import SwiftUI
import Network

struct NetworkDiagnosticsView: View {
    @State private var isNetworkAvailable = false
    @State private var connectionType = "Unknown"
    @State private var testResults = ""
    @State private var isTestingConnection = false
    @ObservedObject private var firebaseService = FirebaseService.shared
    
    private let pathMonitor = NWPathMonitor()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Connection Status
                    statusSection
                    
                    // Firebase Service Status
                    firebaseStatusSection
                    
                    // Network Information
                    networkInfoSection
                    
                    // Connection Test
                    connectionTestSection
                    
                    // Test Results
                    if !testResults.isEmpty {
                        testResultsSection
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Network Diagnostics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                startNetworkMonitoring()
            }
            .onDisappear {
                stopNetworkMonitoring()
            }
        }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connection Status")
                .font(.headline)
            
            HStack {
                Circle()
                    .fill(isNetworkAvailable ? .green : .red)
                    .frame(width: 12, height: 12)
                
                Text("Network: \(isNetworkAvailable ? "Connected" : "Disconnected")")
                    .foregroundColor(isNetworkAvailable ? .green : .red)
            }
            
            HStack {
                Circle()
                    .fill(firebaseService.error == nil ? .green : .red)
                    .frame(width: 12, height: 12)
                
                Text("Firebase: \(firebaseService.error == nil ? "Connected" : "Error")")
                    .foregroundColor(firebaseService.error == nil ? .green : .red)
            }
            
            Text("Connection Type: \(connectionType)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var firebaseStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Firebase Service")
                .font(.headline)
            
            HStack {
                Text("Markers Loaded:")
                Spacer()
                Text("\(firebaseService.markers.count)")
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Loading:")
                Spacer()
                Text(firebaseService.isLoading ? "Yes" : "No")
                    .fontWeight(.medium)
                    .foregroundColor(firebaseService.isLoading ? .orange : .green)
            }
            
            if let error = firebaseService.error {
                Text("Error: \(error)")
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
    }
    
    private var networkInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Network Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• This app uses Firebase Firestore for real-time data")
                Text("• Network connection is required for syncing")
                Text("• Offline data is cached locally")
                Text("• Auto-sync occurs when connection is restored")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var connectionTestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connection Test")
                .font(.headline)
            
            Button(action: testConnection) {
                HStack {
                    if isTestingConnection {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "network")
                    }
                    
                    Text(isTestingConnection ? "Testing..." : "Test Firebase Connection")
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isTestingConnection ? .gray : .blue)
                )
            }
            .disabled(isTestingConnection)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var testResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Results")
                .font(.headline)
            
            ScrollView {
                Text(testResults)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func startNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isNetworkAvailable = path.status == .satisfied
                
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = "WiFi"
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = "Cellular"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = "Ethernet"
                } else {
                    self.connectionType = "Unknown"
                }
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        pathMonitor.start(queue: queue)
    }
    
    private func stopNetworkMonitoring() {
        pathMonitor.cancel()
    }
    
    private func testConnection() {
        isTestingConnection = true
        testResults = ""
        
        Task {
            var results = "=== Firebase Connection Test ===\n"
            results += "Timestamp: \(Date())\n\n"
            
            // Test network availability
            results += "Network Status:\n"
            results += "Available: \(isNetworkAvailable ? "Yes" : "No")\n"
            results += "Type: \(connectionType)\n\n"
            
            // Test Firebase connection
            results += "Firebase Test:\n"
            await firebaseService.fetchMarkers()
            
            if let error = firebaseService.error {
                results += "❌ Error: \(error)\n"
            } else {
                results += "✅ Successfully connected to Firebase\n"
                results += "✅ Loaded \(firebaseService.markers.count) markers\n"
            }
            
            results += "\n=== Test Complete ===\n"
            
            await MainActor.run {
                self.testResults = results
                self.isTestingConnection = false
            }
        }
    }
}

#Preview {
    NetworkDiagnosticsView()
} 