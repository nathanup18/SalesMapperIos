import SwiftUI

struct ConnectionTestView: View {
    @ObservedObject var markerVM: MarkerViewModel
    @ObservedObject var locationManager: LocationManager
    @State private var testResult = ""
    @State private var isTestingConnection = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Firebase Connection Test")
                .font(.headline)
            
            Button("Test Firebase Connection") {
                testFirebaseConnection()
            }
            .disabled(isTestingConnection)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Test Add Marker") {
                testAddMarker()
            }
            .disabled(isTestingConnection)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Verify Latest Marker") {
                verifyLatestMarker()
            }
            .disabled(isTestingConnection)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            if isTestingConnection {
                ProgressView("Testing...")
            }
            
            if !testResult.isEmpty {
                Text(testResult)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private func testFirebaseConnection() {
        isTestingConnection = true
        testResult = ""
        
        Task {
            await markerVM.fetchMarkers()
            
            DispatchQueue.main.async {
                if let error = markerVM.errorMessage {
                    testResult = "❌ Connection failed: \(error)"
                } else {
                    testResult = "✅ Connection successful! Markers: \(markerVM.markers.count)"
                }
                isTestingConnection = false
            }
        }
    }
    
    private func testAddMarker() {
        isTestingConnection = true
        testResult = ""
        
        Task {
            do {
                // Create a test marker with current timestamp
                // REMOVED: No hardcoded coordinates - using live GPS location only
                guard let liveLocation = locationManager.getCurrentLiveLocation() else {
                    await MainActor.run {
                        testResult = "❌ Cannot test marker placement - no live GPS location available"
                        print("📍 App requires real-time location to place markers")
                        isTestingConnection = false
                    }
                    return
                }
                let testCoordinate = liveLocation.coordinate
                let initialCount = markerVM.markers.count
                
                print("🧪 Testing marker placement at: \(testCoordinate.latitude), \(testCoordinate.longitude)")
                print("🧪 Initial marker count: \(initialCount)")
                
                try await markerVM.placeMarker(
                    at: testCoordinate,
                    status: "sold",
                    name: "Test User \(Date().timeIntervalSince1970)",
                    team: 1
                )
                
                // Wait a moment for real-time updates
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                await MainActor.run {
                    let finalCount = markerVM.markers.count
                    print("🧪 Final marker count: \(finalCount)")
                    
                    if finalCount > initialCount {
                        testResult = "✅ Marker saved! Count: \(initialCount) → \(finalCount)"
                    } else {
                        testResult = "⚠️ No error but count unchanged: \(finalCount)"
                    }
                    isTestingConnection = false
                }
                
            } catch {
                await MainActor.run {
                    testResult = "❌ Add marker failed: \(error.localizedDescription)"
                    isTestingConnection = false
                }
            }
        }
    }
    
    private func verifyLatestMarker() {
        guard let latestMarker = markerVM.markers.first else {
            testResult = "❌ No markers found to verify"
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        
        testResult = """
        ✅ Latest Marker Details:
        📍 Location: \(String(format: "%.6f", latestMarker.latitude)), \(String(format: "%.6f", latestMarker.longitude))
        📊 Status: \(latestMarker.status.rawValue) (\(latestMarker.status.displayName))
        👤 Salesman: \(latestMarker.salesman_name)
        🏢 Team: \(latestMarker.team_number)
        🕐 Created: \(formatter.string(from: latestMarker.created_at))
        🆔 ID: \(latestMarker.id ?? "no-id")
        """
    }
}

import CoreLocation 