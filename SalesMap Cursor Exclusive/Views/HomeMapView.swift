import SwiftUI
import MapKit
import CoreLocation
import Combine

struct HomeMapView: View {
    @StateObject private var markerVM = MarkerViewModel()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var gestureManager = MapGestureManager()
    @StateObject private var platformDetector = PlatformDetector.shared
    @StateObject private var lassoManager = LassoToolManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0), // LIVE GPS ONLY - No hardcoded coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var showingSettings = false
    @State private var showingMarkerEditor = false
    @State private var selectedMarkerForEdit: Marker?
    @State private var showingMarkerTypeSelector = false
    @State private var currentSalesman = "John Doe" // TODO: Get from user profile
    @State private var currentTeam = 1 // TODO: Get from user profile
    @State private var showErrorMessage = false
    @State private var errorMessage = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var showingMarkerPlacement = false
    @State private var preloadedEditorView: MarkerEditorView?
    @State private var lastTapTime: CFAbsoluteTime = 0
    
    init() {
        // Public initializer for HomeMapView
    }
    
    // MARK: - Computed Properties for Complex Expressions
    
    // Removed trackMeButton properties since Track Me button was removed
    
    private var locationStatusColor: Color {
        return locationManager.shouldCenterMapOnUser ? Color.purple : Color.green
    }
    
    private var locationStatusText: String {
        return locationManager.shouldCenterMapOnUser ? "Following Location" : "Live Tracking"
    }
    
    private var gpsStatusText: String {
        return locationManager.shouldCenterMapOnUser ? "✅ Live GPS Following" : "✅ Live GPS Active"
    }
    
    private var gpsStatusBackgroundColor: Color {
        return locationManager.shouldCenterMapOnUser ? Color.purple : Color.green
    }
    
    // MARK: - Lasso Tool Components
    
    private var lassoOverlay: some View {
        GeometryReader { geometry in
            LassoDrawingView(
                isDrawing: $lassoManager.isDrawing,
                drawnPath: $lassoManager.drawnPath,
                onPathCompleted: { path in
                    lassoManager.completeLassoPath(
                        path,
                        markers: markerVM.markers,
                        mapRegion: region,
                        screenSize: geometry.size
                    )
                }
            )
            .onAppear {
                // Update screen size when the geometry appears
                lassoManager.updateScreenSize(geometry.size)
            }
            .onChange(of: geometry.size) { newSize in
                // Update screen size when geometry changes
                lassoManager.updateScreenSize(newSize)
            }
        }
        .allowsHitTesting(lassoManager.isActive)
    }
    
    private var lassoModeIndicator: some View {
        Group {
            if lassoManager.isActive && !lassoManager.hasActiveSelection {
                VStack {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: "lasso")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("Lasso Mode")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            Text(lassoManager.isDrawing ? "Draw around markers • Zoom enabled" : "Ready to draw • Tap and drag")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding(.top, 120) // Below GPS status
                .allowsHitTesting(false)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .animation(.easeInOut(duration: 0.3), value: lassoManager.isActive)
            }
        }
    }
    
    private var lassoSelectionSummary: some View {
        HStack(spacing: 12) {
            Image(systemName: "lasso")
                .foregroundColor(.blue)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(lassoManager.selectionSummary)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let analysisResult = lassoManager.analysisResult {
                    Text(analysisResult.selectionArea)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("View Details") {
                lassoManager.showingAnalysisResults = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    // Removed handleTrackMeButtonTap since Track Me button was removed
    
    // MARK: - Main UI Components
    
    private var mapView: some View {
        MapViewRepresentable(
            region: $region,
            markers: markerVM.markers,
            placingMode: markerVM.placingMode,
            currentSalesman: currentSalesman,
            currentTeam: currentTeam,
            onMapTap: { coordinate in
                placeMarker(at: coordinate)
            },
            onMarkerTap: { marker in
                // PERFORMANCE: Start timing marker tap handling
                let tapStartTime = CFAbsoluteTimeGetCurrent()
                
                // OPTIMIZATION: Debounce rapid taps to prevent UI conflicts
                let timeSinceLastTap = tapStartTime - lastTapTime
                if timeSinceLastTap < 0.3 {
                    print("⏱️ PERFORMANCE: Tap debounced (too soon after last tap)")
                    return
                }
                lastTapTime = tapStartTime
                
                // OPTIMIZATION: Immediate UI response without performance overhead
                guard let markerId = marker.id, !markerId.isEmpty else {
                    markerVM.errorMessage = "Invalid marker data"
                    return
                }
                
                // Skip duplicate taps for same marker
                if showingMarkerEditor && selectedMarkerForEdit?.id == markerId {
                    print("⏱️ PERFORMANCE: Duplicate tap for same marker, ignoring")
                    return
                }
                
                // OPTIMIZATION: Immediate state updates for responsive UI
                selectedMarkerForEdit = marker
                
                // PERFORMANCE: Pre-create the editor view to eliminate sheet creation delay
                preloadedEditorView = MarkerEditorView(
                    marker: marker,
                    markerVM: markerVM,
                    onDismiss: {
                        showingMarkerEditor = false
                        selectedMarkerForEdit = nil
                        preloadedEditorView = nil
                    }
                )
                
                // OPTIMIZATION: Show editor immediately after preloading
                showingMarkerEditor = true
                
                // PERFORMANCE: Log total tap handling time
                let tapEndTime = CFAbsoluteTimeGetCurrent()
                let tapDuration = (tapEndTime - tapStartTime) * 1000
                print("⏱️ PERFORMANCE: Marker tap handled in \(String(format: "%.1f", tapDuration))ms")
            },
            gestureManager: gestureManager,
            isLassoActive: lassoManager.isActive
        )
        .ignoresSafeArea()
    }
    
    private var networkStatusBanner: some View {
        Group {
            if markerVM.showNetworkBanner || markerVM.isRetrying {
                VStack {
                    NetworkStatusBanner(
                        isOffline: markerVM.isOffline,
                        isRetrying: markerVM.isRetrying,
                        connectionStatus: markerVM.connectionStatus
                    )
                    Spacer()
                }
                .allowsHitTesting(false) // Don't intercept map gestures
                .transition(.move(edge: .top))
                .animation(.easeInOut(duration: 0.3), value: markerVM.showNetworkBanner)
            }
        }
    }
    
    private var locationStatusIndicator: some View {
        Group {
            if locationManager.isRealTimeTrackingEnabled {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Circle()
                                .fill(locationStatusColor)
                                .frame(width: 8, height: 8)
                                .scaleEffect(locationManager.isUpdatingLocation ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: locationManager.isUpdatingLocation)
                            
                            Text(locationStatusText)
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            if let age = locationManager.getLocationAge() {
                                Text("(\(Int(age))s ago)")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(16)
                        .padding(.trailing, 16)
                        .padding(.bottom, 100) // Above marker buttons
                    }
                }
                .allowsHitTesting(false)
            }
        }
    }
    
    private var topControls: some View {
        // Remove all top center controls - keep only location button (top left) and settings (top right)
        EmptyView()
    }
    
    private var gpsStatusIndicator: some View {
        Group {
            if locationManager.authorizationStatus == .denied {
                VStack {
                    Text("📍 Live GPS Required")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("This app requires live GPS location to place markers. No hardcoded coordinates are used.")
                        .font(.caption)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.red)
                .cornerRadius(8)
                .padding(.horizontal, 16)
            } else if !locationManager.hasValidLiveLocation() {
                VStack {
                    Text("🔄 Getting Live GPS Location...")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Waiting for real-time GPS coordinates. No static locations used.")
                        .font(.caption)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange)
                .cornerRadius(8)
                .padding(.horizontal, 16)
            } else {
                VStack {
                    Text(gpsStatusText)
                        .font(.headline)
                        .foregroundColor(.white)
                    if let location = locationManager.location {
                        VStack(spacing: 2) {
                            Text("📍 \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude))")
                                .font(.caption)
                                .foregroundColor(.white)
                            if locationManager.shouldCenterMapOnUser {
                                Text("🗺️ Map continuously centering on your location")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
                .padding()
                .background(gpsStatusBackgroundColor)
                .cornerRadius(8)
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var locationErrorBanner: some View {
        Group {
            if let locationError = locationManager.locationError {
                LocationStatusBanner(
                    message: locationError,
                    isError: true,
                    onAction: {
                        if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                            locationManager.openLocationSettings()
                        } else {
                            locationManager.requestLocation()
                        }
                    }
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }
    
    private var topNavigationBar: some View {
        HStack {
            // Location Button (Top Left)
            LocationButton(locationManager: locationManager, region: $region)
            
            Spacer()
            
            // Settings Button (Top Right)
            SettingsButton(showingSettings: $showingSettings)
        }
        .padding(.horizontal, 16)
        .padding(.top, locationManager.locationError != nil ? 4 : 8) // Reduced padding if banner is showing
    }
    
    private var bottomSection: some View {
        VStack {
            // Placing Mode Indicator (if active) - but hide when popup is showing
            if markerVM.placingMode != nil && !showingMarkerTypeSelector {
                PlacingModeIndicator(
                    status: markerVM.placingMode!,
                    onCancel: {
                        markerVM.stopPlacing()
                        showingMarkerTypeSelector = false
                    }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            
            // Lasso Selection Summary (if active)
            if lassoManager.hasActiveSelection {
                lassoSelectionSummary
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
            
            // Bottom Controls
            HStack {
                // Lasso Tool Button (Bottom Left)
                LassoToolButton(
                    isActive: lassoManager.isActive,
                    isDrawing: lassoManager.isDrawing,
                    onToggle: {
                        // Toggle behavior - click again to deselect
                        if lassoManager.isActive {
                            print("🎯 USER: Deactivating lasso tool")
                            lassoManager.deactivateLassoTool()
                        } else {
                            print("🎯 USER: Activating lasso tool")
                            lassoManager.activateLassoTool()
                        }
                    }
                )
                .padding(.leading, 16)
                
                Spacer()
                
                // Add Marker Button (Bottom Right)
                AddMarkerButton(showingSelector: $showingMarkerTypeSelector)
                    .padding(.trailing, 16)
            }
            .padding(.bottom, 24)
        }
    }
    
    private var markerTypeSelectorPopup: some View {
        Group {
            if showingMarkerTypeSelector {
                ImprovedMarkerTypeSelectorPopup(
                    markerVM: markerVM,
                    onDismiss: {
                        showingMarkerTypeSelector = false
                        markerVM.stopPlacing()
                    }
                )
            }
        }
    }
    
    private var debugOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("🔍 DEBUG INFO")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Markers: \(markerVM.markers.count)")
                        .font(.caption2)
                        .foregroundColor(.white)
                    
                    Text("Gesture: \(gestureManager.lastGestureType.displayName)")
                        .font(.caption2)
                        .foregroundColor(gestureManager.isGestureActive ? .green : .white)
                    
                    if gestureManager.lastGestureType == .pinch {
                        Text("🤏 Pinch Scale: \(String(format: "%.2f", gestureManager.pinchScale))")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                    
                    Text("Editor: \(showingMarkerEditor ? "YES" : "NO")")
                        .font(.caption2)
                        .foregroundColor(showingMarkerEditor ? .green : .white)
                    
                    Text("Selected: \(selectedMarkerForEdit?.id?.prefix(8) ?? "NONE")")
                        .font(.caption2)
                        .foregroundColor(selectedMarkerForEdit != nil ? .green : .white)
                    
                    Text("Loading: \(markerVM.isLoading ? "YES" : "NO")")
                        .font(.caption2)
                        .foregroundColor(markerVM.isLoading ? .orange : .white)
                    
                    if let error = markerVM.errorMessage {
                        Text("Error: \(error.prefix(20))...")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 100) // Above the add button
        }
        .allowsHitTesting(false) // Don't interfere with map interactions
    }
    
    private var mainContent: some View {
        ZStack {
            // Full-screen Map with Continuous Centering
            mapView
                .allowsHitTesting(!lassoManager.isActive) // Disable map interactions during lasso mode
            
            // Lasso Drawing Overlay (captures gestures when active)
            lassoOverlay
            
            // Lasso Mode Indicator
            lassoModeIndicator
            
            // Network Status Banner
            networkStatusBanner
            
            // Location status removed for cleaner UI
            
            // Redesigned UI Layout
            VStack(spacing: 0) {
                // Top Controls - Track Me Button and Manual Center
                topControls
                
                // Location Status Banner (if there's an error)
                locationErrorBanner
                
                // Top Navigation Bar
                topNavigationBar
                
                Spacer()
                    .allowsHitTesting(false) // Don't intercept map gestures in spacer area
                
                // Bottom Section
                bottomSection
            }
            
            // Redesigned Marker Type Selector Popup
            markerTypeSelectorPopup
        }
    }
    
    private var sheetsAndModifiers: some View {
        mainContent
            .sheet(isPresented: $showingSettings) {
                StatisticsView(markerViewModel: markerVM)
            }
            .sheet(isPresented: $showingMarkerEditor) {
                // PERFORMANCE: Use preloaded view to eliminate creation delay
                if let preloadedView = preloadedEditorView {
                    preloadedView
                        .id("marker-editor-\(selectedMarkerForEdit?.id ?? "unknown")")
                        .onAppear {
                            let editorAppearTime = CFAbsoluteTimeGetCurrent()
                            print("⏱️ PERFORMANCE: MarkerEditorView appeared at \(String(format: "%.3f", editorAppearTime))")
                        }
                } else {
                    // Fallback: Create view inline (should rarely happen with preloading)
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading marker editor...")
                            .foregroundColor(.secondary)
                        Button("Close") {
                            showingMarkerEditor = false
                            selectedMarkerForEdit = nil
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .onAppear {
                        print("⚠️ PERFORMANCE: Fallback editor view loaded (preloading failed)")
                    }
                }
            }
            .alert("Firebase Error", isPresented: .constant(markerVM.errorMessage != nil)) {
                Button("OK") { markerVM.clearError() }
            } message: {
                Text(markerVM.errorMessage ?? "Unknown error")
            }
            .sheet(isPresented: $lassoManager.showingAnalysisResults) {
                if let analysisResult = lassoManager.analysisResult {
                    LassoAnalysisResultsView(
                        analysisResult: analysisResult,
                        onDismiss: {
                            lassoManager.dismissAnalysisResults()
                            lassoManager.deactivateLassoTool() // Exit lasso mode completely
                        },
                        onClearSelection: {
                            lassoManager.clearSelection()
                        }
                    )
                }
            }
            .sheet(isPresented: $showingMarkerPlacement) {
                if let coordinate = selectedCoordinate {
                    MarkerPlacementSheet(
                        coordinate: coordinate,
                        currentSalesman: currentSalesman,
                        currentTeam: currentTeam,
                        markerVM: markerVM,
                        onDismiss: {
                            showingMarkerPlacement = false
                            selectedCoordinate = nil
                        }
                    )
                }
            }
            .alert("Location Error", isPresented: $showErrorMessage) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
    }
    
    private var eventHandlers: some View {
        sheetsAndModifiers
            .onAppear {
                // Request user's location on app launch
                print("📍 App appeared - requesting user location")
                locationManager.requestLocation()
                
                // Show permission prompt if needed
                if locationManager.authorizationStatus == .notDetermined {
                    print("📍 Requesting location permissions for tracking functionality")
                }
            }
            .task {
                await markerVM.fetchMarkers()
            }
            .onChange(of: locationManager.location) { _, newValue in
                if let location = newValue {
                    print("📍 Location updated - centering map on user location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    updateRegionToUserLocation(location)
                }
            }
            .onChange(of: locationManager.authorizationStatus) { _, newStatus in
                // Handle permission changes
                switch newStatus {
                case .authorizedWhenInUse, .authorizedAlways:
                    print("📍 Location permissions granted - requesting current location")
                    locationManager.requestLocation() // Get location immediately when permission is granted
                case .denied, .restricted:
                    print("📍 Location permissions denied - stopping real-time tracking")
                    locationManager.stopContinuousLocationUpdates()
                default:
                    break
                }
            }
            .onChange(of: showingMarkerEditor) { _, newValue in
                // PERFORMANCE: Clean up preloaded view when editor is dismissed
                if !newValue {
                    preloadedEditorView = nil
                    print("⏱️ PERFORMANCE: Cleaned up preloaded editor view")
                }
                
                // Simple validation without excessive logging
                if newValue && selectedMarkerForEdit == nil {
                    showingMarkerEditor = false
                }
            }
            .onReceive(locationManager.$mapRegion) { newRegion in
                updateMapRegion(newRegion)
            }
            .navigationBarTitleDisplayMode(.inline)
    }
    
    var body: some View {
        eventHandlers
    }
    
    private func updateRegionToUserLocation(_ location: CLLocation) {
        withAnimation(.easeInOut(duration: 1.0)) {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        print("📍 Map region updated to user location")
    }
    
    private func placeMarker(at coordinate: CLLocationCoordinate2D) {
        // CRITICAL: Validate that we're using LIVE GPS coordinates only
        guard let liveLocation = locationManager.getCurrentLiveLocation() else {
            print("❌ CRITICAL: Cannot place marker - no live GPS location available")
            print("📍 App requires real-time GPS coordinates to place markers")
            print("⚠️ Hardcoded coordinates have been completely removed")
            
            // Show error to user
            showErrorMessage = true
            errorMessage = "Live GPS location required to place markers. Please ensure location services are enabled and try again."
            return
        }
        
        // Verify we're using the actual live GPS coordinate, not a tap coordinate
        let distanceFromLiveLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            .distance(from: liveLocation)
        
        if distanceFromLiveLocation > 100 { // More than 100 meters from live location
            print("⚠️ WARNING: Marker placement attempted \(String(format: "%.1f", distanceFromLiveLocation))m from live GPS location")
            print("📍 Using live GPS coordinates instead of tap location for accuracy")
        }
        
        // ALWAYS use live GPS coordinates for marker placement
        let actualCoordinate = liveLocation.coordinate
        
        print("📍 PLACING MARKER AT LIVE GPS LOCATION:")
        print("   📌 Coordinates: \(actualCoordinate.latitude), \(actualCoordinate.longitude)")
        print("   🎯 Accuracy: ±\(String(format: "%.1f", liveLocation.horizontalAccuracy))m")
        print("   ⏰ Location Age: \(String(format: "%.1f", Date().timeIntervalSince(liveLocation.timestamp)))s")
        
        selectedCoordinate = actualCoordinate
        showingMarkerPlacement = true
    }
    
    private func updateMapRegion(_ newRegion: MKCoordinateRegion?) {
        // Continuously update map when LocationManager updates region
        if let newRegion = newRegion, locationManager.shouldCenterMapOnUser {
            withAnimation(.easeInOut(duration: 0.5)) {
                region = newRegion
            }
            // Update lasso manager with new region for coordinate conversions
            lassoManager.updateMapRegion(newRegion)
            print("🗺️ Map continuously centered on user location")
        }
    }
}

// MARK: - MapView UIViewRepresentable

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let markers: [Marker]
    let placingMode: String?
    let currentSalesman: String
    let currentTeam: Int
    let onMapTap: (CLLocationCoordinate2D) -> Void
    let onMarkerTap: (Marker) -> Void
    let gestureManager: MapGestureManager
    let isLassoActive: Bool // Add lasso state
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.mapType = .standard
        
        // CRITICAL: Enable user interaction for pinch gestures
        mapView.isUserInteractionEnabled = true  // Required for pinch gestures
        
        // Enable all necessary gestures for smooth interaction
        mapView.isZoomEnabled = true          // Enable pinch-to-zoom
        mapView.isScrollEnabled = true        // Enable panning/dragging
        mapView.isRotateEnabled = true        // Enable rotation gestures
        mapView.isPitchEnabled = false        // Disable 3D tilt
        
        // Configure gesture manager with this map view AFTER enabling interactions
        gestureManager.setupMapView(mapView)
        
        // Configure zoom constraints with gesture manager settings
        let settings = gestureManager.gestureSettings
        mapView.cameraZoomRange = MKMapView.CameraZoomRange(
            minCenterCoordinateDistance: 100 / pow(2.0, settings.maximumZoomScale),
            maxCenterCoordinateDistance: 10000000 / pow(2.0, settings.minimumZoomScale)
        )
        
        // Enable marker clustering with standard configuration
        mapView.preferredConfiguration = MKStandardMapConfiguration()
        
        // Register annotation views for clustering
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "MarkerAnnotation")
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: "ClusterAnnotation")
        
        // Add tap gesture for marker placement
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleMapTap(_:))
        )
        tapGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(tapGesture)
        
        // Platform-specific gesture configuration
        configurePlatformSpecificGestures(mapView, context: context)
        
        // Force initial marker load if we have markers
        if !markers.isEmpty {
            let initialAnnotations = markers.map { MarkerAnnotation(marker: $0) }
            mapView.addAnnotations(initialAnnotations)
            context.coordinator.lastMarkerCount = markers.count
        }
        
        // Set initial gesture state based on lasso tool
        updateGestureControls(mapView, context: context)
        
        return mapView
    }
    
    private func configurePlatformSpecificGestures(_ mapView: MKMapView, context: Context) {
        let platformDetector = PlatformDetector.shared
        
        switch platformDetector.currentPlatform {
        case .iPhone, .iPad:
            configureMobileGestures(mapView, context: context)
        case .macCatalyst:
            configureHybridGestures(mapView, context: context)
        case .macOS:
            configureDesktopGestures(mapView, context: context)
        case .unknown:
            configureDefaultGestures(mapView, context: context)
        }
    }
    
    private func configureMobileGestures(_ mapView: MKMapView, context: Context) {
        // Mobile: Enhanced pinch-to-zoom with haptic feedback
        print("📱 Configuring mobile gestures: Enhanced pinch-to-zoom")
        
        // Ensure user interaction is enabled (critical for pinch gestures)
        mapView.isUserInteractionEnabled = true
        
        // Verify all gestures are enabled
        print("📱 MapView gesture status:")
        print("   - isUserInteractionEnabled: \(mapView.isUserInteractionEnabled)")
        print("   - isZoomEnabled: \(mapView.isZoomEnabled)")
        print("   - Gesture recognizers count: \(mapView.gestureRecognizers?.count ?? 0)")
        
        // List all gesture recognizers for debugging
        mapView.gestureRecognizers?.enumerated().forEach { index, recognizer in
            print("   - Gesture \(index): \(type(of: recognizer)) - enabled: \(recognizer.isEnabled)")
        }
    }
    
    private func configureHybridGestures(_ mapView: MKMapView, context: Context) {
        // Mac Catalyst: Both touch and trackpad/mouse support
        print("🖥️📱 Configuring hybrid gestures: Touch + Trackpad support")
        
        // Enable trackpad gestures for macOS Catalyst
        if let scrollView = mapView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.panGestureRecognizer.allowedTouchTypes = [
                NSNumber(value: UITouch.TouchType.direct.rawValue),
                NSNumber(value: UITouch.TouchType.indirect.rawValue)
            ]
            scrollView.pinchGestureRecognizer?.allowedTouchTypes = [
                NSNumber(value: UITouch.TouchType.direct.rawValue),
                NSNumber(value: UITouch.TouchType.indirect.rawValue)
            ]
        }
        
        // Add scroll wheel support
        addScrollWheelSupport(mapView, context: context)
    }
    
    private func configureDesktopGestures(_ mapView: MKMapView, context: Context) {
        // Desktop: Primarily scroll/trackpad zoom
        print("🖥️ Configuring desktop gestures: Scroll wheel zoom")
        
        addScrollWheelSupport(mapView, context: context)
    }
    
    private func configureDefaultGestures(_ mapView: MKMapView, context: Context) {
        // Safe default configuration
        print("❓ Configuring default gestures")
        
        // Enable basic gestures
        mapView.gestureRecognizers?.forEach { $0.isEnabled = true }
    }
    
    private func addScrollWheelSupport(_ mapView: MKMapView, context: Context) {
        // For now, rely on MapKit's built-in zoom gestures for desktop
        // Custom scroll wheel support can be added later with platform-specific implementations
        
        #if targetEnvironment(macCatalyst)
        // Enable enhanced zoom gestures for Mac Catalyst
        mapView.gestureRecognizers?.forEach { recognizer in
            if recognizer is UIPinchGestureRecognizer {
                recognizer.isEnabled = true
            }
        }
        print("🖥️ Mac Catalyst: Enhanced zoom gestures enabled")
        #endif
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update gesture controls based on lasso state
        updateGestureControls(mapView, context: context)
        
        // Update region if changed significantly
        let threshold: CLLocationDegrees = 0.0001
        let currentCenter = mapView.region.center
        let newCenter = region.center
        let currentSpan = mapView.region.span
        let newSpan = region.span
        
        let regionChanged = abs(currentCenter.latitude - newCenter.latitude) > threshold ||
                           abs(currentCenter.longitude - newCenter.longitude) > threshold ||
                           abs(currentSpan.latitudeDelta - newSpan.latitudeDelta) > threshold ||
                           abs(currentSpan.longitudeDelta - newSpan.longitudeDelta) > threshold
        
        if regionChanged {
            mapView.setRegion(region, animated: true)
        }
        
        // OPTIMIZATION: Efficient marker count-based updates only
        let currentAnnotations = mapView.annotations.compactMap { $0 as? MarkerAnnotation }
        let currentMarkerCount = currentAnnotations.count
        let newMarkerCount = markers.count
        
        if newMarkerCount > currentMarkerCount {
            addNewMarkersOnly(mapView: mapView, currentAnnotations: currentAnnotations, context: context)
        } else if newMarkerCount < currentMarkerCount {
            removeDeletedMarkersOnly(mapView: mapView, currentAnnotations: currentAnnotations, context: context)
        }
        
        context.coordinator.lastMarkerCount = newMarkerCount
        
        // Sync placing mode with coordinator
        if context.coordinator.placingMode != placingMode {
            context.coordinator.updatePlacingMode(placingMode)
        }
    }
    
    private func updateGestureControls(_ mapView: MKMapView, context: Context) {
        // When lasso is active: disable panning, keep zoom enabled
        if isLassoActive {
            mapView.isScrollEnabled = false  // Disable panning/dragging
            mapView.isZoomEnabled = true     // Keep zoom enabled
            print("🎯 LASSO MODE: Panning disabled, zoom enabled")
        } else {
            mapView.isScrollEnabled = true   // Enable panning/dragging
            mapView.isZoomEnabled = true     // Keep zoom enabled
            print("🗺️ NORMAL MODE: All gestures enabled")
        }
    }
    
    private func addNewMarkersOnly(mapView: MKMapView, currentAnnotations: [MarkerAnnotation], context: Context) {
        // Find all new markers that were just added
        let currentMarkerIds = Set(currentAnnotations.compactMap { $0.marker.id })
        let coordinatorManagedIds = context.coordinator.coordinatorManagedMarkers
        
        let newMarkers = markers.filter { marker in
            guard let markerId = marker.id else { return false }
            // Skip if already on map OR already managed by coordinator
            return !currentMarkerIds.contains(markerId) && !coordinatorManagedIds.contains(markerId)
        }
        
        // Add each new marker individually - NO BULK OPERATIONS
        for newMarker in newMarkers {
            let newAnnotation = MarkerAnnotation(marker: newMarker)
            mapView.addAnnotation(newAnnotation)  // ✅ INCREMENTAL ADD
            
            // Track this marker to prevent future duplicates
            if let markerId = newMarker.id {
                context.coordinator.coordinatorManagedMarkers.insert(markerId)
            }
        }
        
        context.coordinator.lastMarkerCount = markers.count
    }
    
    private func removeDeletedMarkersOnly(mapView: MKMapView, currentAnnotations: [MarkerAnnotation], context: Context) {
        // Find markers that were deleted
        let newMarkerIds = Set(markers.compactMap { $0.id })
        let annotationsToRemove = currentAnnotations.filter { annotation in
            guard let markerId = annotation.marker.id else { return false }
            return !newMarkerIds.contains(markerId)
        }
        
        // Remove each deleted marker individually - NO BULK OPERATIONS
        for annotation in annotationsToRemove {
            mapView.removeAnnotation(annotation)  // ✅ INCREMENTAL REMOVE
        }
        
        context.coordinator.lastMarkerCount = markers.count
    }
    
    // STEP 1: Removed updateAnnotations method - no more full refreshes!
    // All marker updates are now purely incremental via addNewMarkersOnly/removeDeletedMarkersOnly
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: MapViewRepresentable
        var placingMode: String?
        var needsAnnotationUpdate = false
        // Removed isHandlingMarkerTap flag - no longer needed for optimized tap handling
        var lastMarkerCount = 0 // Track marker count for incremental updates
        var coordinatorManagedMarkers: Set<String> = [] // Track markers added directly by coordinator
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
            super.init()
            // Initialize with current placing mode
            self.placingMode = parent.placingMode
            // Start with 0 to ensure initial markers are detected as new
            self.lastMarkerCount = 0
        }
        
        // Method to update placing mode from SwiftUI
        func updatePlacingMode(_ newMode: String?) {
            self.placingMode = newMode
        }
        
        // Enhanced marker caching and direct addition through coordinator
        func addMarkerDirectly(_ marker: Marker, to mapView: MKMapView) {
            guard let markerId = marker.id else { return }
            
            // Check both coordinator cache AND existing map annotations
            let existingAnnotations = mapView.annotations.compactMap { $0 as? MarkerAnnotation }
            let existingIds = Set(existingAnnotations.compactMap { $0.marker.id })
            
            if coordinatorManagedMarkers.contains(markerId) || existingIds.contains(markerId) {
                coordinatorManagedMarkers.insert(markerId) // Add to cache for consistency
                return
            }
            
            // Safe to add - not in cache or on map
            let annotation = MarkerAnnotation(marker: marker)
            mapView.addAnnotation(annotation)
            coordinatorManagedMarkers.insert(markerId)
            lastMarkerCount += 1
        }
        
        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            // Check placingMode before proceeding
            guard placingMode != nil else {
                return
            }
            
            // Get tap location and convert to coordinate
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            // Add marker directly via coordinator to bypass SwiftUI state updates
            let tempMarker = Marker(
                coordinate: coordinate,
                status: .notHome,
                salesman_name: parent.currentSalesman,
                team_number: parent.currentTeam
            )
            
            // Add marker directly to map via coordinator - bypasses SwiftUI state
            addMarkerDirectly(tempMarker, to: mapView)
            
            // Then call parent for Firebase save (this will eventually update SwiftUI state)
            parent.onMapTap(coordinate)
        }
        
        @objc func handleScrollWheel(_ gesture: ScrollWheelGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            
            let scrollDelta = gesture.currentScrollDelta
            let location = gesture.location(in: mapView)
            
            // Use gesture manager to handle scroll zoom
            parent.gestureManager.handleScrollGesture(scrollDelta, at: location, in: mapView)
            
            print("🖱️ Scroll wheel gesture: delta=\(scrollDelta), location=\(location)")
        }
        
        // Alternative scroll handling for platforms where scroll wheel events are not directly available
        func handleAlternativeScrollEvent(delta: CGFloat, at location: CGPoint, in mapView: MKMapView) {
            parent.gestureManager.handleScrollGesture(delta, at: location, in: mapView)
        }
        
        // MARK: - UIGestureRecognizerDelegate
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // SIMPLIFIED: Standard gesture handling for map interactions
            return true
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // SIMPLIFIED: No gesture failure requirements
            return false
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            // Handle the start of region changes
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Update parent region for all changes
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
        
        // MARK: - Disable Default Annotation Selection
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            // PERFORMANCE: Start timing MapKit tap detection
            let didSelectStartTime = CFAbsoluteTimeGetCurrent()
            
            // OPTIMIZATION: Streamlined marker tap handling
            guard let markerAnnotation = view.annotation as? MarkerAnnotation,
                  let markerId = markerAnnotation.marker.id, !markerId.isEmpty else {
                print("⏱️ PERFORMANCE: didSelect called but no valid marker found")
                return
            }
            
            // OPTIMIZATION: Immediate deselection to prevent visual selection state
            mapView.deselectAnnotation(view.annotation, animated: false)
            
            // PERFORMANCE: Direct callback (already on main thread, no async needed)
            self.parent.onMarkerTap(markerAnnotation.marker)
            
            // PERFORMANCE: Log MapKit detection time
            let didSelectEndTime = CFAbsoluteTimeGetCurrent()
            let didSelectDuration = (didSelectEndTime - didSelectStartTime) * 1000
            print("⏱️ PERFORMANCE: MapKit didSelect completed in \(String(format: "%.1f", didSelectDuration))ms")
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Handle user location annotation
            if annotation is MKUserLocation {
                return nil
            }
            
            // Handle cluster annotations
            if annotation is MKClusterAnnotation {
                let identifier = "ClusterAnnotation"
                var clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? ClusterAnnotationView
                
                if clusterView == nil {
                    clusterView = ClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    clusterView?.annotation = annotation
                }
                
                return clusterView
            }
            
            // Handle individual marker annotations
            guard let markerAnnotation = annotation as? MarkerAnnotation else {
                return nil
            }
            
            let identifier = "MarkerAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                
                // SIMPLIFIED APPROACH: Use standard MapKit selection
                annotationView?.canShowCallout = false // No callout popup
                annotationView?.isSelected = false
                
                // Enable clustering for individual markers
                annotationView?.clusteringIdentifier = "MarkerCluster"
                annotationView?.displayPriority = .defaultHigh
                
                print("✅ Created new annotation view for marker")
            } else {
                annotationView?.annotation = annotation
                // Ensure no selection state persists
                annotationView?.isSelected = false
                print("✅ Reused annotation view for marker")
            }
            
            // Configure marker appearance based on status
            let marker = markerAnnotation.marker
            configureMarkerView(annotationView!, for: marker)
            
            return annotationView
        }
        
        // REMOVED: Custom gesture handler - using standard MapKit didSelect instead
        
        private func configureMarkerView(_ annotationView: MKMarkerAnnotationView, for marker: Marker) {
            // Configure marker appearance to match the clean style from the provided image
            switch marker.status {
            case .sold:
                // Green circle with white checkmark (no outline)
                annotationView.glyphText = "✓"
                annotationView.glyphTintColor = .white
                annotationView.markerTintColor = .systemGreen
            case .notInterested:
                // Red circle with white X (no outline)
                annotationView.glyphText = "✕"
                annotationView.glyphTintColor = .white
                annotationView.markerTintColor = .systemRed
            case .notHome:
                // Orange circle with white dot (no outline)
                annotationView.glyphText = "•"
                annotationView.glyphTintColor = .white
                annotationView.markerTintColor = .systemOrange
            }
            
            // Configure marker properties for clustering and direct editing
            annotationView.animatesWhenAdded = true // Enable animation for better UX
            annotationView.isDraggable = false // Prevent dragging
            annotationView.isEnabled = true // Keep enabled for tap gestures
            annotationView.isUserInteractionEnabled = true // Ensure touch events work
            
            // Ensure no popup behavior
            annotationView.canShowCallout = false
            annotationView.isSelected = false
            
            // Remove any white outlines or borders for clean appearance
            annotationView.layer.borderWidth = 0
            annotationView.layer.borderColor = UIColor.clear.cgColor
            
            print("✅ Configured marker view for marker: \(marker.id ?? "no-id")")
            
            // Note: title and subtitle are already nil in MarkerAnnotation class
        }
    }
}

// MARK: - MarkerAnnotation

class MarkerAnnotation: NSObject, MKAnnotation {
    var marker: Marker // Made mutable for visual updates
    
    var coordinate: CLLocationCoordinate2D {
        marker.coordinate
    }
    
    // Explicitly disable title and subtitle to prevent any popup behavior
    var title: String? { nil }
    var subtitle: String? { nil }
    
    init(marker: Marker) {
        self.marker = marker
    }
}

// MARK: - ClusterAnnotationView

class ClusterAnnotationView: MKAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        canShowCallout = false
        isDraggable = false
        centerOffset = CGPoint(x: 0, y: -frame.size.height / 2)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        subviews.forEach { $0.removeFromSuperview() }
    }
    
    override var annotation: MKAnnotation? {
        didSet {
            updateClusterView()
        }
    }
    
    private func updateClusterView() {
        guard let cluster = annotation as? MKClusterAnnotation else { return }
        
        let count = cluster.memberAnnotations.count
        let size: CGFloat = sizeForCount(count)
        
        // Remove existing subviews
        subviews.forEach { $0.removeFromSuperview() }
        
        // Create circular background matching app's blue color
        let circleView = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        circleView.backgroundColor = UIColor.systemBlue // Same blue as plus and location buttons
        circleView.layer.cornerRadius = size / 2
        circleView.layer.shadowColor = UIColor.black.cgColor
        circleView.layer.shadowOffset = CGSize(width: 0, height: 2)
        circleView.layer.shadowRadius = 4
        circleView.layer.shadowOpacity = 0.2
        
        // Create count label with app's font styling
        let label = UILabel(frame: circleView.bounds)
        label.text = "\(count)"
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: fontSizeForCount(count), weight: .semibold)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        circleView.addSubview(label)
        addSubview(circleView)
        
        // Update frame
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        centerOffset = CGPoint(x: 0, y: -size / 2)
    }
    
    private func sizeForCount(_ count: Int) -> CGFloat {
        switch count {
        case 2...9:
            return 40
        case 10...99:
            return 50
        case 100...999:
            return 60
        default:
            return 70
        }
    }
    
    private func fontSizeForCount(_ count: Int) -> CGFloat {
        switch count {
        case 2...9:
            return 16
        case 10...99:
            return 18
        case 100...999:
            return 20
        default:
            return 22
        }
    }
}

// MARK: - UI Components

struct LoadingOverlay: View {
    let isOffline: Bool
    
    var body: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            if isOffline {
                Image(systemName: "wifi.slash")
                    .font(.title)
                    .foregroundColor(.white)
                Text("Offline Mode")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 8)
                Text("Using cached data")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Syncing...")
                    .foregroundColor(.white)
                    .padding(.top, 10)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
        )
    }
}

struct LocationButton: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var region: MKCoordinateRegion
    @State private var showingLocationAlert = false
    
    private var buttonColor: Color {
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            return .red
        case .authorizedWhenInUse, .authorizedAlways:
            return locationManager.location != nil ? .green : .blue
        default:
            return .gray
        }
    }
    
    private var buttonIcon: String {
        if locationManager.isUpdatingLocation {
            return "location.circle"
        }
        
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            return "location.slash"
        case .authorizedWhenInUse, .authorizedAlways:
            return locationManager.location != nil ? "location.fill" : "location"
        default:
            return "location"
        }
    }
    
    var body: some View {
        Button(action: {
            handleLocationButtonTap()
        }) {
            ZStack {
                Image(systemName: buttonIcon)
                    .foregroundColor(.white)
                    .font(.title2)
                    .padding(12)
                    .background(buttonColor)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                // Loading indicator
                if locationManager.isUpdatingLocation {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .trim(from: 0, to: 0.3)
                                .stroke(Color.white, lineWidth: 2)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: locationManager.isUpdatingLocation)
                        )
                }
            }
        }
        .alert("Location Services", isPresented: $showingLocationAlert) {
            if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                Button("Open Settings") {
                    locationManager.openLocationSettings()
                }
                Button("Cancel", role: .cancel) { }
            } else {
                Button("OK") { }
            }
        } message: {
            Text(locationManager.locationError ?? "Location services are required to center the map on your current location.")
        }
        .onChange(of: locationManager.locationError) { _, error in
            if error != nil {
                showingLocationAlert = true
            }
        }
    }
    
    private func handleLocationButtonTap() {
        // If we have a current location, center the map
        if let location = locationManager.location {
            withAnimation(.easeInOut(duration: 1.0)) {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
            return
        }
        
        // Otherwise, request location
        locationManager.requestLocation()
    }
}

struct LocationStatusBanner: View {
    let message: String
    let isError: Bool
    let onAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundColor(isError ? .orange : .blue)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isError ? "Location Issue" : "Location Info")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Button(action: onAction) {
                Text(isError ? "Fix" : "OK")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isError ? Color.orange : Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isError ? Color.orange.opacity(0.3) : Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct SettingsButton: View {
    @Binding var showingSettings: Bool
    
    var body: some View {
        Button(action: {
            showingSettings = true
        }) {
            Image(systemName: "gearshape.fill")
                .foregroundColor(.white)
                .font(.title2)
                .padding(12)
                .background(Color.black) // Fully opaque
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}

struct ZoomControls: View {
    @Binding var region: MKCoordinateRegion
    @ObservedObject var gestureManager: MapGestureManager
    @ObservedObject var platformDetector: PlatformDetector
    
    var body: some View {
        VStack(spacing: 8) {
            // Platform-specific zoom info
            if gestureManager.isGestureActive {
                HStack(spacing: 4) {
                    Image(systemName: gestureIcon)
                        .font(.caption2)
                        .foregroundColor(.white)
                    Text(gestureManager.lastGestureType.displayName)
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.8))
                .cornerRadius(12)
            }
            
            // Zoom level indicator
            Text("×\(String(format: "%.1f", gestureManager.currentZoomLevel))")
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
            
            // Zoom controls
            VStack(spacing: 4) {
                Button(action: {
                    gestureManager.zoomIn()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.8))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    gestureManager.zoomOut()
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.8))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    gestureManager.resetZoom()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.gray.opacity(0.8))
                        .clipShape(Circle())
                }
            }
            
            // Platform-specific gesture hints
            if !gestureManager.isGestureActive {
                Text(gestureHint)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(6)
            }
        }
    }
    
    private var gestureIcon: String {
        switch gestureManager.lastGestureType {
        case .pinch: return "hand.draw"
        case .scroll: return "scroll"
        case .button: return "hand.tap"
        case .none: return "hand.raised"
        }
    }
    
    private var gestureHint: String {
        switch platformDetector.preferredZoomMethod {
        case .pinchToZoom: return "👆 Pinch to zoom"
        case .scrollZoom: return "🖱️ Scroll to zoom"
        case .buttonZoom: return "🔘 Use buttons"
        }
    }
}

struct AddMarkerButton: View {
    @Binding var showingSelector: Bool
    
    var body: some View {
        Button(action: {
            showingSelector.toggle()
        }) {
            Image(systemName: "plus")
                .foregroundColor(.white)
                .font(.title2)
                .fontWeight(.bold)
                .padding(16)
                .background(Color.blue) // Fully opaque
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        }
    }
}

struct PlacingModeIndicator: View {
    let status: String
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tap map to place:")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text(displayText(for: status))
                    .font(.headline)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            Button("Cancel") {
                onCancel()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.8))
            .cornerRadius(8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
        )
    }
    
    private func displayText(for status: String) -> String {
        switch status {
        case "sold": return "Sold ✓"
        case "no_interest": return "Not Interested ✕"
        case "not_home": return "Not Home ?"
        default: return status.capitalized
        }
    }
}

// MARK: - Improved Marker Type Selector Popup

struct ImprovedMarkerTypeSelectorPopup: View {
    @ObservedObject var markerVM: MarkerViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        // No background overlay - just the buttons floating
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: 12) { // Reduced spacing from 16 to 12
                    // Sold Button
                    ImprovedMarkerButton(
                        title: "Sold",
                        icon: "checkmark",
                        backgroundColor: .green,
                        isSelected: markerVM.placingMode == "sold"
                    ) {
                        markerVM.startPlacing(mode: "sold")
                    }
                    
                    // Not Interested Button
                    ImprovedMarkerButton(
                        title: "Not Int.",
                        icon: "xmark",
                        backgroundColor: .red,
                        isSelected: markerVM.placingMode == "no_interest"
                    ) {
                        markerVM.startPlacing(mode: "no_interest")
                    }
                    
                    // Not Home Button
                    ImprovedMarkerButton(
                        title: "Not Home",
                        icon: "clock",
                        backgroundColor: .orange,
                        isSelected: markerVM.placingMode == "not_home"
                    ) {
                        markerVM.startPlacing(mode: "not_home")
                    }
                    
                    // Cancel Button - this is the only way to dismiss
                    ImprovedCancelButton {
                        onDismiss()
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100) // Position above the + button
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: markerVM.placingMode)
    }
}

// MARK: - Improved Button Components

struct ImprovedMarkerButton: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .shadow(color: backgroundColor.opacity(0.3), radius: 6, x: 0, y: 3)
                    .frame(width: 160, height: 44)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                // Content with fixed positioning
                HStack {
                    // Left side: Icon and title
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.body)
                            .fontWeight(.bold)
                        
                        Text(title)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Right side: Checkmark (always in same position)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .fontWeight(.bold)
                        .opacity(isSelected ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(width: 160)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ImprovedCancelButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Cancel")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(width: 160, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var markerVM: MarkerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingFullStatistics = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Connection Status
                ConnectionStatusCard(markerVM: markerVM)
                
                // Main Stats Grid (2x2)
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(title: "Sold", value: "\(markerVM.soldCount)", color: .green, icon: "checkmark.circle.fill")
                    StatCard(title: "Not Int.", value: "\(markerVM.notInterestedCount)", color: .red, icon: "xmark.circle.fill")
                    StatCard(title: "Not Home", value: "\(markerVM.notHomeCount)", color: .orange, icon: "questionmark.circle.fill")
                    StatCard(title: "Total", value: "\(markerVM.totalMarkers)", color: .blue, icon: "house.fill")
                }
                .padding(.horizontal)
                
                // Conversion Metrics Grid (2x1)
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "Outreach Ratio",
                        value: String(format: "%.1f%%", markerVM.outreachRatio),
                        color: .indigo,
                        icon: "target"
                    )
                    
                    StatCard(
                        title: "Primary Conv. Rate",
                        value: String(format: "%.1f%%", markerVM.primaryConversionRate),
                        color: .purple,
                        icon: "percent"
                    )
                }
                .padding(.horizontal)
                
                // Enhanced Statistics Button
                Button(action: {
                    showingFullStatistics = true
                }) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("Detailed Analytics")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Hourly & Daily Activity Charts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                
                // Network Debug Info
                if markerVM.isOffline || markerVM.isRetrying {
                    NetworkDebugCard(markerVM: markerVM)
                }
                
                Spacer()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingFullStatistics) {
                StatisticsView(markerViewModel: markerVM)
            }
        }
    }
}

// MARK: - Connection Status Card

struct ConnectionStatusCard: View {
    @ObservedObject var markerVM: MarkerViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(markerVM.isOffline ? Color.red : Color.green)
                    .frame(width: 12, height: 12)
                
                Text(markerVM.connectionStatus)
                    .font(.headline)
                    .foregroundColor(markerVM.isOffline ? .red : .green)
                
                Spacer()
            }
            
            if markerVM.isOffline {
                Text("Working offline - data will sync when connection is restored")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let errorMessage = markerVM.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

// MARK: - Network Debug Card

struct NetworkDebugCard: View {
    @ObservedObject var markerVM: MarkerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.orange)
                Text("Network Debug")
                    .font(.headline)
                    .foregroundColor(.orange)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                DebugRow(label: "Status:", value: markerVM.connectionStatus)
                DebugRow(label: "Is Offline:", value: markerVM.isOffline ? "Yes" : "No")
                DebugRow(label: "Is Retrying:", value: markerVM.isRetrying ? "Yes" : "No")
                DebugRow(label: "Firebase Status:", value: "Connected")
                
                if let errorMessage = markerVM.errorMessage {
                    DebugRow(label: "Last Error:", value: errorMessage)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

struct DebugRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Marker Editor

struct MarkerEditorView: View {
    let marker: Marker
    @ObservedObject var markerVM: MarkerViewModel
    let onDismiss: () -> Void
    
    @State private var selectedStatus: String
    @State private var markerNotes: String
    @State private var isUpdating = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    
    let statusOptions = [
        ("sold", "Sold ✓", Color.green),
        ("no_interest", "Not Interested ✕", Color.red),
        ("not_home", "Not Home ?", Color.orange)
    ]
    
    init(marker: Marker, markerVM: MarkerViewModel, onDismiss: @escaping () -> Void) {
        // PERFORMANCE: Time the editor initialization
        let initStartTime = CFAbsoluteTimeGetCurrent()
        
        // OPTIMIZATION: Clean initialization without performance overhead
        self.marker = marker
        self.markerVM = markerVM
        self.onDismiss = onDismiss
        self._selectedStatus = State(initialValue: marker.status.rawValue)
        self._markerNotes = State(initialValue: marker.notes)
        
        // PERFORMANCE: Log initialization time
        let initEndTime = CFAbsoluteTimeGetCurrent()
        let initDuration = (initEndTime - initStartTime) * 1000
        print("⏱️ PERFORMANCE: MarkerEditorView init completed in \(String(format: "%.1f", initDuration))ms")
    }
    
    var body: some View {
        // PERFORMANCE: Monitor view rendering time
        let _ = PerformanceMonitor.shared.trackOperation("MarkerEditorView body render") {
            // View content will be rendered here
        }
        
        NavigationView {
            ScrollView {
                VStack(spacing: 12) { // Reduced from 16 to 12
                    // Marker Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Marker Details")
                            .font(.headline)
                        
                        HStack {
                            Text("Salesman:")
                            Spacer()
                            Text(marker.salesman_name)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Team:")
                            Spacer()
                            Text("Team \(marker.team_number)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Created:")
                            Spacer()
                            Text(formatDate(marker.created_at))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Status Selection
                    VStack(alignment: .leading, spacing: 12) { // Reduced from 16 to 12
                        Text("Update Status")
                            .font(.headline)
                        
                        VStack(spacing: 10) { // Reduced from 12 to 10
                            // Sold Status
                            Button(action: { selectedStatus = "sold" }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Sold")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text("Successfully completed sale")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedStatus == "sold" {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 24))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 24))
                                    }
                                }
                                .padding(14) // Reduced from 16 to 14
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedStatus == "sold" ? Color.blue.opacity(0.08) : Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedStatus == "sold" ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Not Interested Status
                            Button(action: { selectedStatus = "no_interest" }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "xmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Not Interested")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text("Customer declined offer")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedStatus == "no_interest" {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 24))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 24))
                                    }
                                }
                                .padding(14) // Reduced from 16 to 14
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedStatus == "no_interest" ? Color.blue.opacity(0.08) : Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedStatus == "no_interest" ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Not Home Status
                            Button(action: { selectedStatus = "not_home" }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.orange)
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "questionmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Not Home")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text("No one answered the door")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedStatus == "not_home" {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 24))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 24))
                                    }
                                }
                                .padding(14) // Reduced from 16 to 14
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedStatus == "not_home" ? Color.blue.opacity(0.08) : Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedStatus == "not_home" ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 12) { // Reduced from 16 to 12
                        Text("Notes")
                            .font(.headline)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $markerNotes)
                                .frame(height: 80)
                                .padding(8)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .onChange(of: markerNotes) { oldValue, newValue in
                                    print("📝 NOTES DEBUG - TextEditor changed:")
                                    print("   - Old: '\(oldValue)'")
                                    print("   - New: '\(newValue)'")
                                    print("   - Length: \(newValue.count) characters")
                                }
                            
                            if markerNotes.isEmpty {
                                Text("Add notes about this location...")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) { // Reduced from 16 to 12
                        Button("Cancel") {
                            onDismiss()
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12) // Reduced vertical padding
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            updateMarkerStatus()
                        }) {
                            if isUpdating {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Updating...")
                                }
                            } else {
                                Text("Update Marker")
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12) // Reduced vertical padding
                        .background(Color.blue)
                        .cornerRadius(12)
                        .disabled(isUpdating)
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Delete Button
                    Button(action: { 
                        showingDeleteConfirmation = true 
                    }) {
                        HStack {
                            if isDeleting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Deleting...")
                            } else {
                                Image(systemName: "trash")
                                Text("Delete Marker")
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12) // Reduced vertical padding
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .disabled(isDeleting)
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(16) // Consistent padding
            }
            .navigationTitle("Edit Marker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
        .alert("Delete Marker", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Yes, Delete", role: .destructive) {
                deleteMarker()
            }
        } message: {
            Text("Are you sure you want to delete this marker?")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
    
    private func updateMarkerStatus() {
        isUpdating = true
        
        Task {
            // Convert string status to MarkerStatus enum
            let newStatus: MarkerStatus
            switch selectedStatus {
            case "sold":
                newStatus = .sold
            case "no_interest":
                newStatus = .notInterested
            case "not_home":
                newStatus = .notHome
            default:
                isUpdating = false
                return
            }
            
            // Create updated marker
            var updatedMarker = marker
            updatedMarker.status = newStatus
            updatedMarker.notes = markerNotes
            
            // Update the marker
            await markerVM.updateMarker(updatedMarker)
            
            if markerVM.errorMessage != nil {
                isUpdating = false
                return
            }
            
            isUpdating = false
            onDismiss()
        }
    }
    
    private func deleteMarker() {
        isDeleting = true
        
        Task {
            await markerVM.deleteMarker(marker)
            isDeleting = false
            onDismiss()
        }
    }
}

// MARK: - Network Status Banner

struct NetworkStatusBanner: View {
    let isOffline: Bool
    let isRetrying: Bool
    let connectionStatus: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Status Icon
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.system(size: 16, weight: .medium))
            
            // Status Text
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                if let subtitle = statusSubtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Retry indicator for retrying state
            if isRetrying {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: statusColor))
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .safeAreaInset(edge: .top, spacing: 0) { EmptyView() }
    }
    
    private var statusIcon: String {
        if isRetrying {
            return "arrow.clockwise"
        } else if isOffline {
            return "wifi.slash"
        } else {
            return "wifi"
        }
    }
    
    private var statusColor: Color {
        if isRetrying {
            return .orange
        } else if isOffline {
            return .red
        } else {
            return .green
        }
    }
    
    private var statusTitle: String {
        if isRetrying {
            return "Retrying Connection..."
        } else if isOffline {
            return "Offline Mode"
        } else {
            return "Connected"
        }
    }
    
    private var statusSubtitle: String? {
        if isRetrying {
            return "Attempting to reconnect"
        } else if isOffline {
            return "Data will sync when online"
        } else {
            return nil
        }
    }
    
    private var backgroundColor: Color {
        if isRetrying {
            return Color.orange.opacity(0.1)
        } else if isOffline {
            return Color.red.opacity(0.1)
        } else {
            return Color.green.opacity(0.1)
        }
    }
}

struct MarkerPlacementSheet: View {
    let coordinate: CLLocationCoordinate2D
    let currentSalesman: String
    let currentTeam: Int
    let markerVM: MarkerViewModel
    let onDismiss: () -> Void
    
    @State private var isPlacing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Place Marker at Live GPS Location")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("📍 GPS Coordinates:")
                        .font(.headline)
                    Text("Lat: \(String(format: "%.6f", coordinate.latitude))")
                    Text("Lng: \(String(format: "%.6f", coordinate.longitude))")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Text("Salesman: \(currentSalesman)")
                Text("Team: \(currentTeam)")
                
                if let placingMode = markerVM.placingMode {
                    VStack(spacing: 16) {
                        Text("Status: \(placingMode)")
                            .font(.headline)
                        
                        Button(action: placeMarker) {
                            if isPlacing {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Placing Marker...")
                                }
                            } else {
                                Text("Confirm Placement")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isPlacing)
                    }
                } else {
                    Text("Please select a marker status first")
                        .foregroundColor(.orange)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Live GPS Marker")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    onDismiss()
                }
            )
        }
    }
    
    private func placeMarker() {
        guard let placingMode = markerVM.placingMode else { return }
        
        isPlacing = true
        
        Task {
            do {
                try await markerVM.placeMarker(
                    at: coordinate,
                    status: placingMode,
                    name: currentSalesman,
                    team: currentTeam
                )
                
                await MainActor.run {
                    onDismiss()
                }
            } catch {
                await MainActor.run {
                    markerVM.errorMessage = error.localizedDescription
                    isPlacing = false
                }
            }
        }
    }
}

#Preview {
    HomeMapView()
} 