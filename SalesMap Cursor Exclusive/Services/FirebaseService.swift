import Foundation
import FirebaseCore
import FirebaseFirestore
import CoreLocation
import Combine

@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    @Published var markers: [Marker] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private let markersCollection = "markers"
    private var listenerRegistration: ListenerRegistration?
    
    private init() {}
    
    // OPTIMIZATION: Simplified initialization
    func initialize() {
        startListening()
        Task {
            await fetchMarkers()
        }
    }
    
    // OPTIMIZATION: Streamlined connection test
    private func testFirebaseConnection() async {
        do {
            let testRef = db.collection("connection_test").limit(to: 1)
            _ = try await testRef.getDocuments()
        } catch {
            self.error = "Firebase connection failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - CRUD Operations
    
    func fetchMarkers() async {
        isLoading = true
        error = nil
        
        do {
            let snapshot = try await db.collection(markersCollection)
                .order(by: "created_at", descending: true)
                .getDocuments()
            
            let fetchedMarkers = snapshot.documents.compactMap { document in
                createMarker(from: document)
            }
            
            markers = fetchedMarkers
            
        } catch {
            self.error = "Failed to fetch markers: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func addMarker(_ marker: Marker) async {
        isLoading = true
        error = nil
        
        do {
            let docRef = marker.id?.isEmpty == false 
                ? db.collection(markersCollection).document(marker.id!)
                : db.collection(markersCollection).document()
            
            let data = createFirestoreData(from: marker)
            try await docRef.setData(data)
            
        } catch {
            self.error = "Failed to add marker: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteMarker(by id: String) async {
        isLoading = true
        error = nil
        
        do {
            try await db.collection(markersCollection)
                .document(id)
                .delete()
        } catch {
            self.error = "Failed to delete marker: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Real-time Listener
    
    func startListening() {
        listenerRegistration?.remove()
        
        listenerRegistration = db.collection(markersCollection)
            .order(by: "created_at", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let error = error {
                        self.error = "Real-time listener error: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let snapshot = snapshot else { return }
                    
                    let updatedMarkers = snapshot.documents.compactMap { document in
                        self.createMarker(from: document)
                    }
                    
                    // OPTIMIZATION: Only update if meaningful change
                    if self.markers.count != updatedMarkers.count ||
                       !self.markers.elementsEqual(updatedMarkers, by: { $0.id == $1.id && $0.status == $1.status }) {
                        self.markers = updatedMarkers
                    }
                }
            }
    }
    
    func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
        print("⏹️ Real-time listener stopped")
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        error = nil
    }
    
    // MARK: - Additional Utility Methods
    
    func updateMarker(_ marker: Marker) async {
        guard let id = marker.id else {
            error = "Cannot update marker without ID"
            return
        }
        
        print("🔥 FIREBASE UPDATE - Step 1: Starting Firebase update")
        print("   📍 Marker ID: \(id)")
        print("   📊 Status: \(marker.status.rawValue)")
        print("   📝 Notes: '\(marker.notes)' (length: \(marker.notes.count))")
        print("   👤 Salesman: \(marker.salesman_name)")
        
        isLoading = true
        error = nil
        
        do {
            let data = createFirestoreData(from: marker)
            print("🔥 FIREBASE UPDATE - Step 2: Created Firestore data")
            print("   📊 Data keys: \(Array(data.keys))")
            print("   📝 Notes in data: '\(data["notes"] as? String ?? "MISSING")'")
            print("   📊 Status in data: \(data["status"] as? String ?? "MISSING")")
            
            try await db.collection(markersCollection)
                .document(id)
                .setData(data, merge: true)
            
            print("✅ FIREBASE UPDATE - Step 3: Successfully updated marker in Firebase")
            print("   📍 Document ID: \(id)")
            print("   📝 Notes saved: '\(marker.notes)'")
            
        } catch {
            self.error = "Failed to update marker: \(error.localizedDescription)"
            print("❌ FIREBASE UPDATE ERROR - Step 3: Failed to update marker")
            print("   🔥 Error: \(error)")
        }
        
        isLoading = false
    }
    
    // Batch operations for efficiency
    func batchAddMarkers(_ markers: [Marker]) async {
        isLoading = true
        error = nil
        
        let batch = db.batch()
        
        do {
            for marker in markers {
                let docRef = marker.id?.isEmpty == false 
                    ? db.collection(markersCollection).document(marker.id!)
                    : db.collection(markersCollection).document()
                
                let data = createFirestoreData(from: marker)
                batch.setData(data, forDocument: docRef)
            }
            
            try await batch.commit()
            print("✅ Batch added \(markers.count) markers to Firebase")
            
        } catch {
            self.error = "Failed to batch add markers: \(error.localizedDescription)"
            print("❌ Error batch adding markers: \(error)")
        }
        
        isLoading = false
    }
    
    // Get markers with filtering (useful for statistics)
    func getMarkers(forTeam team: Int) -> [Marker] {
        markers.filter { $0.team_number == team }
    }
    
    func getMarkers(forStatus status: MarkerStatus) -> [Marker] {
        markers.filter { $0.status == status }
    }
    
    func getMarkers(forSalesman name: String) -> [Marker] {
        markers.filter { $0.salesman_name == name }
    }
    
    // MARK: - Manual Data Conversion (without FirestoreSwift)
    
    private func createMarker(from document: QueryDocumentSnapshot) -> Marker? {
        let data = document.data()
        
        print("🔥 FIREBASE DECODE - Parsing document: \(document.documentID)")
        print("   📊 Available keys: \(Array(data.keys))")
        print("   📝 Notes in document: '\(data["notes"] as? String ?? "MISSING")'")
        
        guard let latitude = data["latitude"] as? Double,
              let longitude = data["longitude"] as? Double,
              let statusString = data["status"] as? String,
              let status = MarkerStatus(rawValue: statusString),
              let salesmanName = data["salesman_name"] as? String,
              let teamNumber = data["team_number"] as? Int else {
            print("❌ Failed to parse marker data from document: \(document.documentID)")
            return nil
        }
        
        // Handle created_at field (could be Timestamp or Date)
        let createdAt: Date
        if let timestamp = data["created_at"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else if let date = data["created_at"] as? Date {
            createdAt = date
        } else {
            createdAt = Date() // Fallback
        }
        
        // Handle notes field (may not exist in older markers)
        let notes = data["notes"] as? String ?? ""
        print("   📝 Decoded notes: '\(notes)' (length: \(notes.count))")
        
        var marker = Marker(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            status: status,
            salesman_name: salesmanName,
            team_number: teamNumber
        )
        
        marker.id = document.documentID
        marker.created_at = createdAt
        marker.notes = notes // Set the notes field
        
        print("✅ FIREBASE DECODE - Successfully created marker with notes: '\(marker.notes)'")
        
        return marker
    }
    
    private func createFirestoreData(from marker: Marker) -> [String: Any] {
        return [
            "latitude": marker.latitude,
            "longitude": marker.longitude,
            "status": marker.status.rawValue,
            "salesman_name": marker.salesman_name,
            "team_number": marker.team_number,
            "created_at": marker.created_at,
            "notes": marker.notes
        ]
    }
} 
