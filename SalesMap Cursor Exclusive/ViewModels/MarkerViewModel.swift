import Foundation
import Combine
import CoreLocation
import SwiftUI

// OPTIMIZATION: Consolidated connection state to reduce @Published properties
enum ConnectionState: Equatable {
    case connecting
    case connected
    case connectedNoData
    case offline
    case retrying
    case firebaseError
    
    var isOffline: Bool {
        switch self {
        case .offline: return true
        default: return false
        }
    }
    
    var statusMessage: String {
        switch self {
        case .connecting: return "Connecting..."
        case .connected: return "Connected - Real-time Active"
        case .connectedNoData: return "Connected - No Data"
        case .offline: return "Offline Mode"
        case .retrying: return "Reconnecting..."
        case .firebaseError: return "Firebase Error"
        }
    }
    
    var shouldShowBanner: Bool {
        switch self {
        case .offline, .retrying, .firebaseError: return true
        default: return false
        }
    }
    
    var isRetrying: Bool {
        switch self {
        case .retrying: return true
        default: return false
        }
    }
}

@MainActor
class MarkerViewModel: ObservableObject {
    @Published var markers: [Marker] = []
    @Published var placingMode: String? = nil // "sold", "no_interest", etc.
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // OPTIMIZATION: Combine related state to reduce @Published properties
    @Published private(set) var connectionState = ConnectionState.connecting
    
    // Firebase service integration
    private let firebaseService = FirebaseService.shared
    
    private var pendingOperations: [PendingOperation] = []
    private var cancellables = Set<AnyCancellable>()
    private var lastFetchTime: Date?
    
    // Cache for offline functionality
    private let cacheKey = "cached_markers"
    private let pendingOpsKey = "pending_marker_operations"
    
    // OPTIMIZATION: Computed properties instead of @Published for derived state
    var isOffline: Bool { connectionState.isOffline }
    var connectionStatus: String { connectionState.statusMessage }
    var showNetworkBanner: Bool { connectionState.shouldShowBanner }
    var isRetrying: Bool { connectionState.isRetrying }
    
    init() {
        print("🚀 MarkerViewModel init() called")
        
        // Always load cached data first for immediate UI
        loadCachedMarkers()
        loadPendingOperations()
        
        print("📊 After cache load - marker count: \(markers.count)")
        
        // Initialize Firebase integration
        initializeFirebase()
        
        print("✅ MarkerViewModel initialization complete")
    }
    
    // MARK: - Firebase Integration
    
    private func initializeFirebase() {
        isLoading = true
        connectionState = .connecting
        
        print("🚀 Initializing MarkerViewModel with Firebase...")
        print("🔥 Firebase service instance: \(firebaseService)")
        print("🔥 Current Firebase markers: \(firebaseService.markers.count)")
        
        // Set up observers for Firebase service state changes first
        print("👀 Setting up Firebase observers...")
        setupFirebaseObservers()
        
        // Check if Firebase service already has data
        if !firebaseService.markers.isEmpty {
            print("✅ Firebase service already has \(firebaseService.markers.count) markers - syncing immediately")
            syncMarkersEfficiently(firebaseService.markers)
        } else {
            print("📥 No data in Firebase service - starting listener and fetching...")
            // Ensure Firebase listener is started (it should already be started by StartupManager)
            firebaseService.startListening()
            
            // Fetch initial data
            Task {
                await fetchMarkers()
                print("✅ Initial data fetch completed")
            }
        }
        
        print("✅ Firebase initialization complete")
    }
    
    private func setupFirebaseObservers() {
        // OPTIMIZATION: Single observer with debouncing to prevent update loops
        print("🔄 Setting up optimized Firebase observer...")
        
        // Single observer with 100ms debouncing to prevent excessive updates
        firebaseService.$markers
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .removeDuplicates { oldMarkers, newMarkers in
                // Only update if actual content changed, not just array reference
                oldMarkers.count == newMarkers.count && 
                oldMarkers.elementsEqual(newMarkers) { $0.id == $1.id && $0.status == $1.status }
            }
            .sink { [weak self] newMarkers in
                self?.syncMarkersEfficiently(newMarkers)
            }
            .store(in: &cancellables)
    }
    
    // OPTIMIZATION: Efficient sync without triggering unnecessary updates
    private func syncMarkersEfficiently(_ newMarkers: [Marker]) {
        let previousCount = markers.count
        
        // Only update if there's a meaningful difference
        guard markers.count != newMarkers.count || 
              !markers.elementsEqual(newMarkers, by: { $0.id == $1.id && $0.status == $1.status }) else {
            return
        }
        
        // Preserve local unsaved markers
        var syncedMarkers = newMarkers
        for localMarker in markers {
            if localMarker.id == nil || !newMarkers.contains(where: { $0.id == localMarker.id }) {
                syncedMarkers.append(localMarker)
            }
        }
        
        markers = syncedMarkers
        
        // Update connection state based on data
        if firebaseService.error != nil {
            connectionState = .firebaseError
            errorMessage = firebaseService.error
        } else if !newMarkers.isEmpty {
            connectionState = .connected
        } else {
            connectionState = .connectedNoData
        }
        
        // Cache if data changed significantly
        if abs(previousCount - syncedMarkers.count) > 0 {
            cacheMarkersIfNeeded()
        }
    }
    
    // MARK: - Marker Placing Control
    
    func startPlacing(mode: String) {
        print("🎯 startPlacing() called with mode: \(mode)")
        placingMode = mode
        print("✅ Placing mode set to: \(placingMode ?? "nil")")
    }
    
    func stopPlacing() {
        print("⏹️ stopPlacing() called")
        placingMode = nil
        print("✅ Placing mode reset to: \(placingMode ?? "nil")")
    }
    
    var isPlacing: Bool {
        placingMode != nil
    }
    
    func placeMarker(at coordinate: CLLocationCoordinate2D, status: String, name: String, team: Int) async throws {
        // CRITICAL VALIDATION: Ensure we're not using hardcoded coordinates
        if coordinate.latitude == 0 && coordinate.longitude == 0 {
            print("❌ CRITICAL ERROR: Attempted to place marker at (0,0) - invalid coordinates")
            throw MarkerError.invalidLocation("Cannot place marker at coordinates (0,0). Live GPS location required.")
        }
        
        // Validate coordinate ranges (basic sanity check)
        guard coordinate.latitude >= -90 && coordinate.latitude <= 90 &&
              coordinate.longitude >= -180 && coordinate.longitude <= 180 else {
            print("❌ CRITICAL ERROR: Invalid coordinate ranges")
            throw MarkerError.invalidLocation("Invalid GPS coordinates. Latitude must be -90 to 90, longitude must be -180 to 180.")
        }
        
        print("📍 PLACING MARKER WITH LIVE GPS COORDINATES:")
        print("   📌 Coordinates: \(coordinate.latitude), \(coordinate.longitude)")
        print("   👤 Salesman: \(name)")
        print("   🏢 Team: \(team)")
        print("   📊 Status: \(status)")
        print("   ⏰ Timestamp: \(Date())")
        
        // Validate status
        guard let markerStatus = MarkerStatus(rawValue: status) else {
            throw MarkerError.invalidStatus("Invalid marker status: \(status)")
        }
        
        // Create marker with live GPS coordinates
        let marker = Marker(
            coordinate: coordinate,
            status: markerStatus,
            salesman_name: name,
            team_number: team
        )
        
        // Add to local array immediately for UI responsiveness
        await MainActor.run {
            markers.append(marker)
            print("✅ Marker added to local array - total markers: \(markers.count)")
        }
        
        // Save to cache
        cacheMarkers()
        
        // Save to Firebase in background
        await firebaseService.addMarker(marker)
        
        // Check if Firebase service has an error
        if let firebaseError = firebaseService.error {
            print("❌ Failed to save marker to Firebase: \(firebaseError)")
            // Remove from local array if Firebase save failed
            await MainActor.run {
                if let index = markers.firstIndex(where: { $0.id == marker.id }) {
                    markers.remove(at: index)
                    print("🔄 Marker removed from local array due to Firebase error")
                }
            }
            throw MarkerError.firebaseError(firebaseError)
        } else {
            print("✅ Marker saved to Firebase successfully")
        }
    }
    
    // MARK: - Core Data Operations (Firebase-powered)
    
    func fetchMarkers() async {
        isLoading = true
        print("🔄 Fetching markers from Firebase")
        
        // Fetch from Firebase service
        await firebaseService.fetchMarkers()
        
        // Always sync with Firebase service state
        syncMarkersEfficiently(firebaseService.markers)
        
        isLoading = false
    }
    
    func deleteMarker(_ marker: Marker) async {
        let deleteStartTime = CFAbsoluteTimeGetCurrent()
        print("🗑️ DELETE DEBUG - Step 1: Starting marker deletion at \(deleteStartTime)")
        print("   📍 Marker ID: \(marker.id ?? "NO-ID")")
        print("   📊 Marker Status: \(marker.status.rawValue)")
        print("   👤 Salesman: \(marker.salesman_name)")
        print("   📍 Coordinate: \(marker.latitude), \(marker.longitude)")
        print("   📊 Total markers before delete: \(markers.count)")
        
        guard let markerId = marker.id else {
            print("❌ DELETE ERROR - Step 2: No marker ID")
            print("   🔧 SELF-CORRECTION: Setting error message")
            errorMessage = "Cannot delete marker without ID"
            return
        }
        
        print("✅ DELETE DEBUG - Step 3: Valid marker ID confirmed")
        print("   📍 Marker ID: \(markerId)")
        
        // Validate marker exists in local array
        let markerIndex = markers.firstIndex(where: { $0.id == markerId })
        if markerIndex == nil {
            print("⚠️ DELETE WARNING - Step 4: Marker not found in local array")
            print("   🔧 SELF-CORRECTION: Marker may have been deleted already")
        } else {
            print("✅ DELETE DEBUG - Step 4: Marker found in local array at index \(markerIndex!)")
        }
        
        print("🔄 DELETE DEBUG - Step 5: Setting loading state")
        isLoading = true
        
        // Delete from Firebase FIRST (not in background)
        let firebaseStartTime = CFAbsoluteTimeGetCurrent()
        print("🔥 DELETE DEBUG - Step 6: Calling Firebase delete at \(firebaseStartTime)")
        
        await firebaseService.deleteMarker(by: markerId)
        
        let firebaseEndTime = CFAbsoluteTimeGetCurrent()
        print("🔥 DELETE DEBUG - Step 7: Firebase delete completed at \(firebaseEndTime)")
        print("   ⏱️ Firebase delete duration: \((firebaseEndTime - firebaseStartTime) * 1000)ms")
        
        // Check for Firebase errors
        if let error = firebaseService.error {
            print("❌ DELETE ERROR - Step 8: Firebase delete failed")
            print("   🔥 Firebase error: \(error)")
            print("   🔧 SELF-CORRECTION: Setting error message and stopping")
            errorMessage = "Failed to delete marker: \(error)"
            isLoading = false
            return
        }
        
        print("✅ DELETE DEBUG - Step 9: Firebase delete successful")
        
        // REMOVED: Manual local array update - let real-time listener handle it
        // This ensures the UI reflects the exact database state
        print("   🔄 Real-time listener will automatically update local state")
        
        // Sync with Firebase service state to ensure UI reflects database changes
        syncMarkersEfficiently(firebaseService.markers)
        
        isLoading = false
        
        let deleteEndTime = CFAbsoluteTimeGetCurrent()
        print("✅ DELETE DEBUG - Step 10: Delete operation completed at \(deleteEndTime)")
        print("   ⏱️ Total delete duration: \((deleteEndTime - deleteStartTime) * 1000)ms")
        print("   📊 Final marker count: \(markers.count)")
        print("   📍 Marker still exists: \(markers.contains(where: { $0.id == markerId }) ? "YES" : "NO")")
    }
    
    func updateMarker(_ marker: Marker) async {
        // OPTIMIZATION: Minimal logging for performance
        guard let markerId = marker.id else {
            errorMessage = "Cannot update marker: missing ID"
            return
        }
        
        // Update local state immediately for responsive UI
        if let index = markers.firstIndex(where: { $0.id == markerId }) {
            markers[index] = marker
        }
        
        isLoading = true
        
        // Update in Firebase - real-time listener will handle sync automatically
        await firebaseService.updateMarker(marker)
        
        // Handle errors efficiently
        if let error = firebaseService.error {
            errorMessage = "Failed to update marker: \(error)"
            // Revert local change on error
            syncMarkersEfficiently(firebaseService.markers)
        }
        
        isLoading = false
    }
    
    // MARK: - Statistics and Filtering
    
    func getMarkers(for timeframe: StatisticsTimeframe, salesmanName: String? = nil, teamNumber: Int? = nil) -> [Marker] {
        let calendar = Calendar.current
        let now = Date()
        
        // 🧠 Step 1: Log initial state
        print("🔍 DEBUG: getMarkers called with:")
        print("   📅 Timeframe: \(timeframe)")
        print("   👤 Salesman: \(salesmanName ?? "nil")")
        print("   🏢 Team: \(teamNumber?.description ?? "nil")")
        print("   📊 Total markers available: \(markers.count)")
        
        // Log sample of available data with dates
        if !markers.isEmpty {
            let sampleSize = min(5, markers.count)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            print("   📋 Sample markers with dates:")
            for i in 0..<sampleSize {
                let marker = markers[i]
                print("      \(i+1). Date: \(dateFormatter.string(from: marker.createdDate)), Team: \(marker.team_number), Status: \(marker.status.rawValue)")
            }
        }
        
        let filteredByTime = markers.filter { marker in
            switch timeframe {
            case .daily:
                return calendar.isDate(marker.createdDate, inSameDayAs: now)
            case .weekly:
                // Get the start of the current week (Sunday)
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? 
                                calendar.date(byAdding: .day, value: -7, to: now) ?? now
                return marker.createdDate >= startOfWeek
            case .monthly:
                // Get the start of the current month
                let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? 
                                 calendar.date(byAdding: .month, value: -1, to: now) ?? now
                return marker.createdDate >= startOfMonth
            case .yearly:
                // Get the start of the current year
                let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? 
                                calendar.date(byAdding: .year, value: -1, to: now) ?? now
                return marker.createdDate >= startOfYear
            case .allTime:
                return true // Return all markers regardless of date
            }
        }
        
        // 🧠 Step 2: Log time filtering results with date ranges
        print("   ⏰ After time filtering: \(filteredByTime.count) markers")
        
        // Log the actual date range being used for filtering
        switch timeframe {
        case .weekly:
            if let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                print("   📅 Weekly range: From \(dateFormatter.string(from: startOfWeek)) to now")
            }
        case .monthly:
            if let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                print("   📅 Monthly range: From \(dateFormatter.string(from: startOfMonth)) to now")
            }
        case .yearly:
            if let startOfYear = calendar.dateInterval(of: .year, for: now)?.start {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                print("   📅 Yearly range: From \(dateFormatter.string(from: startOfYear)) to now")
            }
        case .daily:
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            print("   📅 Daily range: Today (\(dateFormatter.string(from: now)))")
        case .allTime:
            print("   📅 All time: No date filtering")
        }
        
        let finalFiltered = filteredByTime.filter { marker in
            if let salesmanName = salesmanName, marker.salesman_name != salesmanName {
                return false
            }
            if let teamNumber = teamNumber, marker.team_number != teamNumber {
                return false
            }
            return true
        }
        
        // 🧠 Step 3: Log final filtering results
        print("   ✅ Final filtered result: \(finalFiltered.count) markers")
        
        // 🧠 Step 4: Log breakdown by status for debugging
        if !finalFiltered.isEmpty {
            let soldCount = finalFiltered.filter { $0.status == .sold }.count
            let notInterestedCount = finalFiltered.filter { $0.status == .notInterested }.count
            let notHomeCount = finalFiltered.filter { $0.status == .notHome }.count
            print("   📊 Status breakdown:")
            print("      ✅ Sold: \(soldCount)")
            print("      ❌ Not Interested: \(notInterestedCount)")
            print("      🏠 Not Home: \(notHomeCount)")
        } else {
            print("   ⚠️ WARNING: No markers found for the given filters!")
            
            // Debug: Check what teams and salesmen are available
            let availableTeams = Set(markers.map { $0.team_number })
            let availableSalesmen = Set(markers.map { $0.salesman_name })
            print("   🔍 Available teams: \(Array(availableTeams).sorted())")
            print("   🔍 Available salesmen: \(Array(availableSalesmen).sorted())")
        }
        
        return finalFiltered
    }
    
    // MARK: - Hourly & Daily Statistics
    
    /// Gets hourly marker data for statistics charts
    /// - Parameters:
    ///   - hourRange: Range of hours to include (e.g., 9...17 for 9AM-5PM)
    ///   - timeframe: Overall timeframe to filter markers
    ///   - salesmanName: Optional salesman filter
    ///   - teamNumber: Optional team filter
    func getHourlyMarkerData(hourRange: ClosedRange<Int> = 0...23, 
                           for timeframe: StatisticsTimeframe = .weekly,
                           salesmanName: String? = nil, 
                           teamNumber: Int? = nil) -> [HourlyData] {
        let filteredMarkers = getMarkers(for: timeframe, salesmanName: salesmanName, teamNumber: teamNumber)
        let calendar = Calendar.current
        
        // Group markers by hour
        let grouped = Dictionary(grouping: filteredMarkers) { marker in
            calendar.component(.hour, from: marker.createdDate)
        }
        
        // Create data points for each hour in the range
        return hourRange.map { hour in
            let count = grouped[hour]?.count ?? 0
            let hourString = hour == 0 ? "12AM" : 
                           hour < 12 ? "\(hour)AM" : 
                           hour == 12 ? "12PM" : "\(hour - 12)PM"
            
            return HourlyData(
                hour: hour,
                label: hourString,
                count: count,
                markers: grouped[hour] ?? []
            )
        }
    }
    
    /// Gets daily marker data for statistics charts
    /// - Parameters:
    ///   - dayRange: Range of weekdays to include (1=Sunday, 7=Saturday)
    ///   - timeframe: Overall timeframe to filter markers
    ///   - salesmanName: Optional salesman filter
    ///   - teamNumber: Optional team filter
    func getDailyMarkerData(dayRange: ClosedRange<Int> = 1...7,
                          for timeframe: StatisticsTimeframe = .weekly,
                          salesmanName: String? = nil,
                          teamNumber: Int? = nil) -> [DailyData] {
        let filteredMarkers = getMarkers(for: timeframe, salesmanName: salesmanName, teamNumber: teamNumber)
        let calendar = Calendar.current
        
        // Group markers by weekday
        let grouped = Dictionary(grouping: filteredMarkers) { marker in
            calendar.component(.weekday, from: marker.createdDate)
        }
        
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        // Create data points for each day in the range
        return dayRange.map { dayIndex in
            let count = grouped[dayIndex]?.count ?? 0
            let dayName = dayNames[dayIndex - 1]
            
            return DailyData(
                weekday: dayIndex,
                label: dayName,
                count: count,
                markers: grouped[dayIndex] ?? []
            )
        }
    }
    
    /// Gets markers for a specific hour
    func getMarkers(forHour hour: Int, 
                   timeframe: StatisticsTimeframe = .weekly,
                   salesmanName: String? = nil,
                   teamNumber: Int? = nil) -> [Marker] {
        let filteredMarkers = getMarkers(for: timeframe, salesmanName: salesmanName, teamNumber: teamNumber)
        let calendar = Calendar.current
        
        return filteredMarkers.filter { marker in
            calendar.component(.hour, from: marker.createdDate) == hour
        }
    }
    
    /// Gets markers for a specific weekday
    func getMarkers(forWeekday weekday: Int,
                   timeframe: StatisticsTimeframe = .weekly,
                   salesmanName: String? = nil,
                   teamNumber: Int? = nil) -> [Marker] {
        let filteredMarkers = getMarkers(for: timeframe, salesmanName: salesmanName, teamNumber: teamNumber)
        let calendar = Calendar.current
        
        return filteredMarkers.filter { marker in
            calendar.component(.weekday, from: marker.createdDate) == weekday
        }
    }
    
    func getTeamNumbers() -> [Int] {
        Array(Set(markers.map { $0.team_number })).sorted()
    }
    
    func getSalesmen(for teamNumber: Int? = nil) -> [String] {
        let filtered = teamNumber != nil ? markers.filter { $0.team_number == teamNumber } : markers
        return Array(Set(filtered.map { $0.salesman_name })).sorted()
    }
    
    func getMarkers(forTeam team: Int) -> [Marker] {
        markers.filter { $0.team_number == team }
    }
    
    // MARK: - Debug & Validation
    
    /// Test timeframe filtering specifically
    func testTimeframeFiltering() {
        print("🧪 ===== TESTING TIMEFRAME FILTERING =====")
        
        for timeframe in StatisticsTimeframe.allCases {
            let filtered = getMarkers(for: timeframe)
            print("📅 \(timeframe.rawValue): \(filtered.count) markers")
        }
        
        print("🧪 ===== TIMEFRAME FILTERING TEST COMPLETE =====")
    }
    
    /// Simple test to validate data filtering logic
    func testDataFiltering() {
        print("🧪 ===== TESTING DATA FILTERING =====")
        
        // NO MORE HARDCODED COORDINATES - App requires live GPS location
        if markers.isEmpty {
            print("📍 No markers found - app requires live GPS location to create markers")
            print("⚠️ REMOVED: All hardcoded coordinates have been eliminated")
            print("🎯 To create markers, user must be at actual physical location")
        }
        
        // Test filtering scenarios
        print("🔍 Testing filtering scenarios:")
        
        // Test 1: All markers
        let allMarkers = getMarkers(for: .allTime)
        print("   All time: \(allMarkers.count) markers")
        
        // Test 2: Team 1 markers
        let team1Markers = getMarkers(for: .allTime, teamNumber: 1)
        print("   Team 1: \(team1Markers.count) markers")
        
        // Test 3: Team 2 markers
        let team2Markers = getMarkers(for: .allTime, teamNumber: 2)
        print("   Team 2: \(team2Markers.count) markers")
        
        // Test 4: Specific salesman
        let johnMarkers = getMarkers(for: .allTime, salesmanName: "John Doe", teamNumber: 1)
        print("   John Doe (Team 1): \(johnMarkers.count) markers")
        
        // Test 5: Non-existent team
        let nonExistentTeam = getMarkers(for: .allTime, teamNumber: 999)
        print("   Non-existent team 999: \(nonExistentTeam.count) markers")
        
        // Test 6: Non-existent salesman
        let nonExistentSalesman = getMarkers(for: .allTime, salesmanName: "Non Existent", teamNumber: 1)
        print("   Non-existent salesman: \(nonExistentSalesman.count) markers")
        
        print("🧪 ===== END TESTING =====")
    }
    
    /// Comprehensive debug method to validate data state and filtering
    func debugDataState() {
        print("🔍 ===== COMPREHENSIVE DATA DEBUG =====")
        print("📊 Total markers in system: \(markers.count)")
        
        if markers.isEmpty {
            print("⚠️ CRITICAL: No markers found in system!")
            return
        }
        
        // Team analysis
        let teamNumbers = getTeamNumbers()
        print("🏢 Available teams: \(teamNumbers)")
        
        for teamNumber in teamNumbers {
            let teamMarkers = getMarkers(forTeam: teamNumber)
            let soldCount = teamMarkers.filter { $0.status == .sold }.count
            let notInterestedCount = teamMarkers.filter { $0.status == .notInterested }.count
            let notHomeCount = teamMarkers.filter { $0.status == .notHome }.count
            
            print("   Team \(teamNumber): \(teamMarkers.count) total (Sold: \(soldCount), Not Int: \(notInterestedCount), Not Home: \(notHomeCount))")
            
            // Salesman analysis for this team
            let salesmen = getSalesmen(for: teamNumber)
            print("      Salesmen: \(salesmen)")
            
            for salesman in salesmen {
                let salesmanMarkers = getMarkers(for: .allTime, salesmanName: salesman, teamNumber: teamNumber)
                let salesmanSold = salesmanMarkers.filter { $0.status == .sold }.count
                print("         \(salesman): \(salesmanMarkers.count) total (\(salesmanSold) sold)")
            }
        }
        
        // Test specific filtering scenarios
        print("🧪 Testing filtering scenarios:")
        
        // Test 1: All time data
        let allTimeMarkers = getMarkers(for: .allTime)
        print("   All time: \(allTimeMarkers.count) markers")
        
        // Test 2: Weekly data
        let weeklyMarkers = getMarkers(for: .weekly)
        print("   Weekly: \(weeklyMarkers.count) markers")
        
        // Test 3: Team-specific data (first team)
        if let firstTeam = teamNumbers.first {
            let teamSpecificMarkers = getMarkers(for: .allTime, teamNumber: firstTeam)
            print("   Team \(firstTeam) (all time): \(teamSpecificMarkers.count) markers")
            
            // Test 4: Salesman-specific data (first salesman in first team)
            let teamSalesmen = getSalesmen(for: firstTeam)
            if let firstSalesman = teamSalesmen.first {
                let salesmanSpecificMarkers = getMarkers(for: .allTime, salesmanName: firstSalesman, teamNumber: firstTeam)
                print("   \(firstSalesman) in Team \(firstTeam) (all time): \(salesmanSpecificMarkers.count) markers")
            }
        }
        
        print("🔍 ===== END DATA DEBUG =====")
    }
    
    /// Validates that marker timestamps are properly stored and logs sample data
    func validateMarkerTimestamps() {
        print("🕐 TIMESTAMP VALIDATION - Total markers: \(markers.count)")
        
        guard !markers.isEmpty else {
            print("⚠️ No markers available for timestamp validation")
            return
        }
        
        // Log first 3 marker timestamps for verification
        let sampleMarkers = Array(markers.prefix(3))
        for (index, marker) in sampleMarkers.enumerated() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            
            print("📍 Marker \(index + 1):")
            print("   🕐 Created: \(dateFormatter.string(from: marker.createdDate))")
            print("   📊 Status: \(marker.status.rawValue)")
            print("   👤 Salesman: \(marker.salesman_name)")
            
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: marker.createdDate)
            let weekday = calendar.component(.weekday, from: marker.createdDate)
            let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            
            print("   ⏰ Hour: \(hour) (\(hour == 0 ? "12AM" : hour < 12 ? "\(hour)AM" : hour == 12 ? "12PM" : "\(hour-12)PM"))")
            print("   📅 Weekday: \(weekday) (\(dayNames[weekday-1]))")
        }
        
        // Validate hour and day distribution
        let hourlyData = getHourlyMarkerData()
        let dailyData = getDailyMarkerData()
        
        print("📊 HOURLY DISTRIBUTION:")
        let nonZeroHours = hourlyData.filter { $0.count > 0 }
        for data in nonZeroHours.prefix(5) {
            print("   \(data.label): \(data.count) markers")
        }
        
        print("📊 DAILY DISTRIBUTION:")
        let nonZeroDays = dailyData.filter { $0.count > 0 }
        for data in nonZeroDays {
            print("   \(data.label): \(data.count) markers")
        }
        
        print("✅ Timestamp validation completed")
    }
    
    // MARK: - Statistics Properties
    
    var soldCount: Int {
        markers.filter { $0.status == .sold }.count
    }
    
    var notInterestedCount: Int {
        markers.filter { $0.status == .notInterested }.count
    }
    
    var notHomeCount: Int {
        markers.filter { $0.status == .notHome }.count
    }
    
    var totalMarkers: Int {
        markers.count
    }
    
    var primaryConversionRate: Double {
        let totalContacts = notInterestedCount + soldCount
        guard totalContacts > 0 else { return 0.0 }
        return (Double(soldCount) / Double(totalContacts)) * 100.0
    }
    
    var outreachRatio: Double {
        let totalAttempts = totalMarkers
        guard totalAttempts > 0 else { return 0.0 }
        return (Double(soldCount) / Double(totalAttempts)) * 100.0
    }
    
    // MARK: - Cache Management
    
    private func loadCachedMarkers() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cachedMarkers = try? JSONDecoder().decode([Marker].self, from: data) {
            markers = cachedMarkers
            print("📱 Loaded \(cachedMarkers.count) markers from cache")
        }
    }
    
    private func cacheMarkers() {
        if let data = try? JSONEncoder().encode(markers) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            print("💾 Cached \(markers.count) markers")
        }
    }
    
    private func loadPendingOperations() {
        if let data = UserDefaults.standard.data(forKey: pendingOpsKey),
           let operations = try? JSONDecoder().decode([PendingOperation].self, from: data) {
            pendingOperations = operations
            print("📱 Loaded \(operations.count) pending operations")
        }
    }
    
    private func savePendingOperations() {
        if let data = try? JSONEncoder().encode(pendingOperations) {
            UserDefaults.standard.set(data, forKey: pendingOpsKey)
        }
    }
    
    private func addPendingOperation(_ operation: PendingOperation) {
        pendingOperations.append(operation)
        savePendingOperations()
    }
    
    // MARK: - Manual Sync and Refresh Methods
    
    func forceSyncNow() async {
        await fetchMarkers()
    }
    
    func refreshData() async {
        await fetchMarkers()
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: pendingOpsKey)
        pendingOperations.removeAll()
        markers.removeAll()
        print("🗑️ Cleared cache and pending operations")
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
        firebaseService.clearError()
    }
    
    // MARK: - Cache and Validation
    
    private func cacheMarkersIfNeeded() {
        cacheMarkers()
        
        // Run timestamp validation after loading markers
        if markers.count > 0 {
            validateMarkerTimestamps()
        }
    }
    
    // MARK: - Sample Data (REMOVED HARDCODED COORDINATES)
    private func getFallbackSampleData() -> [Marker] {
        // NO MORE HARDCODED COORDINATES - App must use live GPS location
        print("⚠️ WARNING: No live location available - cannot create sample markers")
        print("📍 App requires real GPS coordinates to place markers")
        return []
    }
}

// MARK: - Supporting Types

enum MarkerError: LocalizedError {
    case notInPlacingMode
    case invalidStatus(String)
    case firebaseError(String)
    case invalidLocation(String)
    
    var errorDescription: String? {
        switch self {
        case .notInPlacingMode:
            return "Cannot place marker - not in placing mode"
        case .invalidStatus(let status):
            return "Invalid marker status: \(status)"
        case .firebaseError(let message):
            return "Firebase error: \(message)"
        case .invalidLocation(let message):
            return "Invalid location: \(message)"
        }
    }
}

enum StatisticsTimeframe: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    case allTime = "All Time"
}

struct PendingOperation: Codable {
    let id: UUID
    let type: OperationType
    let marker: Marker
    let timestamp: Date
    
    init(type: OperationType, marker: Marker) {
        self.id = UUID()
        self.type = type
        self.marker = marker
        self.timestamp = Date()
    }
    
    enum OperationType: String, Codable {
        case create, update, delete
    }
}

// MARK: - Statistics Data Models

struct HourlyData: Identifiable {
    let id = UUID()
    let hour: Int
    let label: String
    let count: Int
    let markers: [Marker]
    
    var percentage: Double {
        // This can be calculated relative to total markers in the dataset
        return Double(count)
    }
}

struct DailyData: Identifiable {
    let id = UUID()
    let weekday: Int
    let label: String
    let count: Int
    let markers: [Marker]
    
    var percentage: Double {
        // This can be calculated relative to total markers in the dataset
        return Double(count)
    }
} 
