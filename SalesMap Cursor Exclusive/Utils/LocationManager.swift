import Foundation
import CoreLocation
import Combine
import UIKit
import MapKit

@MainActor
class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled = false
    @Published var locationError: String?
    @Published var isUpdatingLocation = false
    @Published var isRealTimeTrackingEnabled = false
    
    // Computed property for easy access to user coordinates
    var userLocation: CLLocationCoordinate2D? {
        return location?.coordinate
    }
    
    // Map centering functionality
    @Published var shouldCenterMapOnUser = false
    @Published var mapRegion: MKCoordinateRegion?
    
    // Real-time tracking configuration
    private var realTimeUpdateTimer: Timer?
    private var lastLocationUpdate: Date?
    private let realTimeUpdateInterval: TimeInterval = 2 // 2 seconds for continuous updates
    private let significantLocationChangeThreshold: CLLocationDistance = 5 // 5 meters for high precision
    
    // Map centering configuration
    private let mapSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // Tight zoom level
    private let minimumMovementForRecentering: CLLocationDistance = 10 // 10 meters before recentering
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // Update every 5 meters for real-time tracking
        
        // Check current authorization status
        authorizationStatus = locationManager.authorizationStatus
        updateLocationEnabledStatus()
        
        // Request permission if not determined
        if authorizationStatus == .notDetermined {
            print("📍 Requesting location permission on LocationManager init")
            locationManager.requestWhenInUseAuthorization()
        }
        
        // Start real-time tracking immediately if permission already granted
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            print("📍 Permission already granted - starting real-time location updates")
            startContinuousLocationUpdates()
        }
    }
    
    // MARK: - Real-Time Location Tracking with Map Centering
    
    func startContinuousLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("📍 Cannot start continuous updates - permission not granted")
            return
        }
        
        print("📍 Starting continuous real-time location updates with map centering")
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // High precision for real-time tracking
        locationManager.startUpdatingLocation()
        isRealTimeTrackingEnabled = true
        shouldCenterMapOnUser = true // Enable automatic map centering
        
        // Set up timer for logging and validation
        realTimeUpdateTimer = Timer.scheduledTimer(withTimeInterval: realTimeUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.logCurrentLocation()
            }
        }
    }
    
    func stopContinuousLocationUpdates() {
        print("📍 Stopping continuous location updates and map centering")
        locationManager.stopUpdatingLocation()
        isRealTimeTrackingEnabled = false
        shouldCenterMapOnUser = false // Disable automatic map centering
        realTimeUpdateTimer?.invalidate()
        realTimeUpdateTimer = nil
    }
    
    private func logCurrentLocation() async {
        if let location = location {
            let age = Date().timeIntervalSince(location.timestamp)
            print("📍 LIVE GPS: \(location.coordinate.latitude), \(location.coordinate.longitude) (±\(String(format: "%.1f", location.horizontalAccuracy))m, \(String(format: "%.1f", age))s old)")
        } else {
            print("📍 No live location available")
        }
    }
    
    // MARK: - Map Centering Functions
    
    func centerMapOnUserLocation() {
        guard let location = location else {
            print("📍 Cannot center map - no location available")
            return
        }
        
        let newRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: mapSpan
        )
        
        mapRegion = newRegion
        print("🗺️ Map centered on user location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    private func shouldRecenterMap(for newLocation: CLLocation) -> Bool {
        guard let currentRegion = mapRegion else { return true } // First time centering
        
        let currentCenter = CLLocation(
            latitude: currentRegion.center.latitude,
            longitude: currentRegion.center.longitude
        )
        
        let distance = newLocation.distance(from: currentCenter)
        return distance > minimumMovementForRecentering
    }
    
    private func updateMapRegionForLocation(_ location: CLLocation) {
        guard shouldCenterMapOnUser else { return }
        
        if shouldRecenterMap(for: location) {
            let newRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: mapSpan
            )
            
            mapRegion = newRegion
            print("🗺️ CONTINUOUS CENTERING: Map recentered on user location")
            print("   📌 New center: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
    
    // MARK: - Public Interface
    
    func requestLocationPermission() {
        print("📍 Requesting location permission")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() {
        locationError = nil
        
        switch authorizationStatus {
        case .notDetermined:
            print("📍 Requesting location permission")
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            locationError = "Location access denied. Please enable location services in Settings to use live GPS tracking."
        case .restricted:
            locationError = "Location access restricted. This may be due to parental controls."
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 Permission granted - starting location updates")
            startContinuousLocationUpdates()
        @unknown default:
            locationError = "Unknown location authorization status."
        }
    }
    
    // Get the most recent live location
    func getCurrentLiveLocation() -> CLLocation? {
        guard let location = location else {
            print("📍 No live location available")
            return nil
        }
        
        let age = Date().timeIntervalSince(location.timestamp)
        if age > 30 { // Location older than 30 seconds
            print("📍 Warning: Location is \(String(format: "%.1f", age))s old")
        }
        
        return location
    }
    
    // Validate that we have a fresh, accurate location
    func hasValidLiveLocation() -> Bool {
        guard let location = location else { return false }
        
        let age = Date().timeIntervalSince(location.timestamp)
        let isRecent = age < 60 // Less than 1 minute old
        let isAccurate = location.horizontalAccuracy < 50 // Better than 50m accuracy
        
        return isRecent && isAccurate
    }
    
    private func updateLocationEnabledStatus() {
        isLocationEnabled = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    func openLocationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Debug and Status Methods
    
    func getLocationStatusDescription() -> String {
        var status = "Location Status:\n"
        status += "• Authorization: \(authorizationStatusDescription)\n"
        status += "• Current Location: \(location != nil ? "✅" : "❌")\n"
        status += "• Updating: \(isUpdatingLocation ? "✅" : "❌")\n"
        status += "• Real-time Tracking: \(isRealTimeTrackingEnabled ? "✅" : "❌")\n"
        if let error = locationError {
            status += "• Error: \(error)\n"
        }
        if let loc = location {
            status += "• Coordinates: \(String(format: "%.6f", loc.coordinate.latitude)), \(String(format: "%.6f", loc.coordinate.longitude))\n"
            status += "• Accuracy: \(String(format: "%.1f", loc.horizontalAccuracy))m\n"
        }
        return status
    }
    
    private var authorizationStatusDescription: String {
        switch authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .authorizedWhenInUse: return "When In Use"
        case .authorizedAlways: return "Always"
        @unknown default: return "Unknown"
        }
    }
    
    // MARK: - Battery Optimization Helpers
    
    func getLocationAge() -> TimeInterval? {
        guard let lastUpdate = lastLocationUpdate else { return nil }
        return Date().timeIntervalSince(lastUpdate)
    }
    
    func isLocationFresh(maxAge: TimeInterval = 300) -> Bool {
        guard let age = getLocationAge() else { return false }
        return age <= maxAge
    }
    
    func getBatteryOptimizedAccuracy() -> CLLocationAccuracy {
        return isRealTimeTrackingEnabled ? kCLLocationAccuracyNearestTenMeters : kCLLocationAccuracyBest
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        // Validate location accuracy (ignore locations with poor accuracy)
        guard newLocation.horizontalAccuracy < 100 else {
            print("📍 Location accuracy too poor: \(newLocation.horizontalAccuracy)m - ignoring")
            return
        }
        
        Task { @MainActor in
            // Check if this is a significant location change for real-time tracking
            let isSignificantChange = self.location?.distance(from: newLocation) ?? Double.greatestFiniteMagnitude > self.significantLocationChangeThreshold
            
            // Always update with the latest location
            self.location = newLocation
            self.locationError = nil
            self.lastLocationUpdate = Date()
            
            // Log live GPS coordinates with detailed info
            let accuracy = String(format: "%.1f", newLocation.horizontalAccuracy)
            let speed = newLocation.speed >= 0 ? String(format: "%.1f", newLocation.speed * 3.6) : "N/A" // Convert m/s to km/h
            let timestamp = DateFormatter().string(from: newLocation.timestamp)
            
            if self.isRealTimeTrackingEnabled {
                print("📍 REAL-TIME GPS UPDATE:")
                print("   📌 Coordinates: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
                print("   🎯 Accuracy: ±\(accuracy)m")
                print("   🚗 Speed: \(speed) km/h")
                print("   ⏰ Timestamp: \(timestamp)")
                
                if isSignificantChange {
                    let distance = self.location?.distance(from: newLocation) ?? 0
                    print("   📏 Movement: \(String(format: "%.1f", distance))m from last position")
                }
            } else {
                print("📍 GPS LOCATION RECEIVED: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude) (±\(accuracy)m)")
            }
            
            // Update UI state
            self.isUpdatingLocation = false
            
            // Update map region
            self.updateMapRegionForLocation(newLocation)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isUpdatingLocation = false
            
            if let clError = error as? CLError {
                switch clError.code {
                case .locationUnknown:
                    self.locationError = "Unable to determine location. Please try again."
                    print("📍 ERROR: Location unknown")
                case .denied:
                    self.locationError = "Location access denied. Please enable location services in Settings."
                    print("📍 ERROR: Location access denied")
                case .network:
                    self.locationError = "Network error while getting location. Check your connection."
                    print("📍 ERROR: Network error during location request")
                case .headingFailure:
                    self.locationError = "Unable to determine heading."
                case .regionMonitoringDenied, .regionMonitoringFailure:
                    self.locationError = "Region monitoring not available."
                case .regionMonitoringSetupDelayed:
                    self.locationError = "Region monitoring setup delayed."
                case .regionMonitoringResponseDelayed:
                    self.locationError = "Region monitoring response delayed."
                case .geocodeFoundNoResult:
                    self.locationError = "No location results found."
                case .geocodeFoundPartialResult:
                    self.locationError = "Partial location results found."
                case .geocodeCanceled:
                    self.locationError = "Location request was canceled."
                case .deferredFailed:
                    self.locationError = "Deferred location updates failed."
                case .deferredNotUpdatingLocation:
                    self.locationError = "Deferred location updates not available."
                case .deferredAccuracyTooLow:
                    self.locationError = "Accuracy too low for deferred updates."
                case .deferredDistanceFiltered:
                    self.locationError = "Distance filter too small for deferred updates."
                case .deferredCanceled:
                    self.locationError = "Deferred location updates canceled."
                case .rangingUnavailable:
                    self.locationError = "Ranging unavailable."
                case .rangingFailure:
                    self.locationError = "Ranging failed."
                case .promptDeclined:
                    self.locationError = "Location prompt was declined."
                case .historicalLocationError:
                    self.locationError = "Historical location data error."
                @unknown default:
                    self.locationError = "Unknown location error: \(error.localizedDescription)"
                }
            } else {
                self.locationError = "Location error: \(error.localizedDescription)"
            }
            
            print("❌ LOCATION ERROR: \(self.locationError ?? "Unknown")")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
            self.updateLocationEnabledStatus()
            self.locationError = nil
            
            switch status {
            case .notDetermined:
                print("📍 Location permission: Not determined")
            case .denied:
                print("📍 Location permission: DENIED - stopping all location updates")
                self.stopContinuousLocationUpdates()
                self.locationError = "Location access denied. Please enable location services in Settings."
            case .restricted:
                print("📍 Location permission: RESTRICTED - stopping all location updates")
                self.stopContinuousLocationUpdates()
                self.locationError = "Location access restricted. This may be due to parental controls."
            case .authorizedWhenInUse:
                print("📍 Location permission: GRANTED (When In Use) - starting real-time tracking")
                self.startContinuousLocationUpdates()
            case .authorizedAlways:
                print("📍 Location permission: GRANTED (Always) - starting real-time tracking")
                self.startContinuousLocationUpdates()
            @unknown default:
                print("📍 Location permission: Unknown status")
                self.locationError = "Unknown location authorization status."
            }
        }
    }
} 