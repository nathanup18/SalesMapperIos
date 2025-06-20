import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - Helper Functions for Coordinate Comparison
private func coordinatesAreEqual(_ lhs: CLLocationCoordinate2D?, _ rhs: CLLocationCoordinate2D?) -> Bool {
    guard let lhs = lhs, let rhs = rhs else {
        return lhs == nil && rhs == nil
    }
    let epsilon: Double = 1e-10
    return abs(lhs.latitude - rhs.latitude) < epsilon && 
           abs(lhs.longitude - rhs.longitude) < epsilon
}

struct TestMarkerView: View {
    @StateObject private var markerVM = MarkerViewModel()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var gestureManager = MapGestureManager()
    @StateObject private var platformDetector = PlatformDetector.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0), // LIVE GPS ONLY - No hardcoded coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0), // LIVE GPS ONLY - No hardcoded coordinates
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @State private var isWaitingForLocation = true
    @State private var locationPermissionDenied = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Stats Header
                HStack {
                    StatBox(title: "Sold", count: markerVM.soldCount, color: .green)
                    StatBox(title: "Not Interested", count: markerVM.notInterestedCount, color: .red)
                    StatBox(title: "Not Home", count: markerVM.notHomeCount, color: .orange)
                }
                .padding()
                
                // Map with gesture support
                ZStack {
                    Map(position: $position) {
                        // Display existing markers
                        ForEach(markerVM.markers, id: \.id) { marker in
                            Annotation(
                                marker.salesman_name,
                                coordinate: CLLocationCoordinate2D(
                                    latitude: marker.latitude,
                                    longitude: marker.longitude
                                )
                            ) {
                                MarkerPin(marker: marker)
                            }
                        }
                        
                        // Show user location if available
                        if let userLocation = locationManager.userLocation {
                            Annotation("You", coordinate: userLocation) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                    .background(Circle().fill(.white).frame(width: 30, height: 30))
                            }
                        }
                    }
                    .mapStyle(.standard)
                    .onMapCameraChange { context in
                        // Update region for gesture manager
                        region = context.region
                    }
                    .onTapGesture(coordinateSpace: .local) { location in
                        // Handle map tap for marker placement
                        print("🗺️ Map tapped at: \(location)")
                    }
                    
                    // Gesture overlay for enhanced zoom control
                    GestureOverlay(gestureManager: gestureManager)
                    
                    // Enhanced zoom controls with gesture feedback
                    VStack {
                        HStack {
                            Spacer()
                            TestZoomControls(
                                position: $position,
                                gestureManager: gestureManager,
                                platformDetector: platformDetector
                            )
                        }
                        Spacer()
                    }
                    .padding()
                }
                
                // Control Buttons
                HStack {
                    Button("Place Test Marker") {
                        placeTestMarker()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(locationManager.location == nil)
                    
                    Button("Refresh") {
                        Task {
                            await markerVM.fetchMarkers()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("Test Markers")
            .task {
                await markerVM.fetchMarkers()
            }
            .onAppear {
                locationManager.requestLocationPermission()
                
                // Configure gesture manager
                Task { @MainActor in
                    // Setup gesture manager after view appears
                    gestureManager.updateGestureSettings(platformDetector.getOptimalGestureSettings())
                }
            }
            .onReceive(locationManager.$location) { newLocation in
                handleLocationUpdate(newLocation?.coordinate)
            }
            .onReceive(locationManager.$authorizationStatus) { newValue in
                handleAuthorizationChange(newValue)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleLocationUpdate(_ location: CLLocationCoordinate2D?) {
        guard let location = location else { return }
        
        // Update map position to user location
        let newRegion = MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        withAnimation(.easeInOut(duration: 1.0)) {
            position = .region(newRegion)
            region = newRegion
        }
        
        print("📍 User location updated: \(location)")
    }
    
    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startContinuousLocationUpdates()
        case .denied, .restricted:
            print("⚠️ Location access denied")
        case .notDetermined:
            locationManager.requestLocationPermission()
        @unknown default:
            print("❓ Unknown location authorization status")
        }
    }
    
    private func placeTestMarker() {
        // CRITICAL: Only use live GPS coordinates for marker placement
        guard let liveLocation = locationManager.getCurrentLiveLocation() else {
            print("❌ CRITICAL: Cannot place test marker - no live GPS location available")
            print("📍 App requires real-time GPS coordinates to place markers")
            print("⚠️ All hardcoded coordinates have been removed")
            return
        }
        
        let coordinate = liveLocation.coordinate
        
        print("📍 PLACING TEST MARKER AT LIVE GPS LOCATION:")
        print("   📌 Coordinates: \(coordinate.latitude), \(coordinate.longitude)")
        print("   🎯 Accuracy: ±\(String(format: "%.1f", liveLocation.horizontalAccuracy))m")
        print("   ⏰ Location Age: \(String(format: "%.1f", Date().timeIntervalSince(liveLocation.timestamp)))s")
        
        Task {
            do {
                try await markerVM.placeMarker(
                    at: coordinate,
                    status: MarkerStatus.sold.rawValue,
                    name: "Test User",
                    team: 1
                )
                print("✅ Test marker placed successfully at live GPS location")
            } catch {
                print("❌ Failed to place test marker: \(error)")
            }
        }
    }
}

struct StatBox: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct MarkerPin: View {
    let marker: Marker
    
    var body: some View {
        VStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.title2)
                .background(
                    Circle()
                        .fill(.white)
                        .frame(width: 30, height: 30)
                        .shadow(radius: 2)
                )
            
            Text(marker.salesman_name)
                .font(.caption)
                .padding(4)
                .background(.white.opacity(0.9))
                .cornerRadius(4)
                .shadow(radius: 1)
        }
    }
    
    private var statusIcon: String {
        switch marker.status {
        case .sold: return "checkmark.circle.fill"
        case .notInterested: return "xmark.circle.fill"
        case .notHome: return "house.slash.fill"
        }
    }
    
    private var statusColor: Color {
        switch marker.status {
        case .sold: return .green
        case .notInterested: return .red
        case .notHome: return .orange
        }
    }
}

// MARK: - Supporting Views

struct GestureOverlay: View {
    @ObservedObject var gestureManager: MapGestureManager
    
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .gesture(
                // Custom pinch gesture for enhanced control
                MagnificationGesture()
                    .onChanged { value in
                        // Handle pinch gesture changes
                        print("🤏 Pinch gesture: \(value)")
                    }
                    .onEnded { value in
                        print("🤏 Pinch gesture ended: \(value)")
                    }
            )
    }
}

struct TestZoomControls: View {
    @Binding var position: MapCameraPosition
    @ObservedObject var gestureManager: MapGestureManager
    @ObservedObject var platformDetector: PlatformDetector
    
    var body: some View {
        VStack(spacing: 8) {
            // Gesture status indicator
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
                .background(Color.purple.opacity(0.8))
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
                Button(action: zoomIn) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.purple.opacity(0.8))
                        .clipShape(Circle())
                }
                
                Button(action: zoomOut) {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.purple.opacity(0.8))
                        .clipShape(Circle())
                }
                
                Button(action: resetZoom) {
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
    
    private func zoomIn() {
        gestureManager.zoomIn()
        updateMapPosition()
    }
    
    private func zoomOut() {
        gestureManager.zoomOut()
        updateMapPosition()
    }
    
    private func resetZoom() {
        gestureManager.resetZoom()
        updateMapPosition()
    }
    
    private func updateMapPosition() {
        // Update map position based on gesture manager's current zoom
        // For now, let the gesture manager handle zoom updates directly
        // The MapCameraPosition will be updated through the map's built-in zoom handling
        print("🔍 Zoom level updated to: \(gestureManager.currentZoomLevel)")
    }
}

#Preview {
    TestMarkerView()
} 

