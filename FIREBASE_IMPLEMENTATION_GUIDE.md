# 🔥 Firebase Implementation Guide

## 🗑️ **Step 1: Remove Supabase Dependencies (REQUIRED)**

### Remove from Xcode Project:
1. **Open your Xcode project**
2. **Select your project in the navigator**
3. **Go to your app target → Package Dependencies**
4. **Find "supabase-swift" in the list**
5. **Click the minus (-) button to remove it**
6. **Clean Build Folder**: Product → Clean Build Folder

---

## 🚀 **Step 2: Firebase Setup**

### 2.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `SalesMap`
4. Enable Google Analytics (optional)
5. Create project

### 2.2 Add iOS App to Firebase
1. In Firebase Console, click "Add app" → iOS
2. **Bundle ID**: `com.yourcompany.SalesMap-Cursor-Exclusive` (check your current bundle ID)
3. **App nickname**: `SalesMap iOS`
4. Download `GoogleService-Info.plist`
5. **IMPORTANT**: Drag this file into your Xcode project root (same level as Info.plist)

### 2.3 Install Firebase SDK
1. In Xcode: File → Add Package Dependencies
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select "Up to Next Major Version" with latest version
4. Add these products:
   - **FirebaseCore** (required)
   - **FirebaseFirestore** (database)
   - **FirebaseAuth** (authentication)
   - **FirebaseStorage** (file storage, if needed)

---

## 🔧 **Step 3: Code Implementation**

### 3.1 Configure Firebase in App Delegate

Create or update your App Delegate:

```swift
// In your main App file (e.g., SalesMapApp.swift)
import SwiftUI
import FirebaseCore

@main
struct SalesMapApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 3.2 Create Firebase Service

Create a new file: `Services/FirebaseService.swift`

```swift
import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    @Published var markers: [Marker] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private let markersCollection = "markers"
    
    private init() {
        print("🔥 Firebase Service initialized")
    }
    
    // MARK: - CRUD Operations
    
    func fetchMarkers() async {
        isLoading = true
        error = nil
        
        do {
            let snapshot = try await db.collection(markersCollection)
                .order(by: "created_at", descending: true)
                .getDocuments()
            
            let fetchedMarkers = try snapshot.documents.compactMap { document in
                try document.data(as: Marker.self)
            }
            
            markers = fetchedMarkers
            print("✅ Fetched \(fetchedMarkers.count) markers from Firebase")
            
        } catch {
            self.error = "Failed to fetch markers: \(error.localizedDescription)"
            print("❌ Error fetching markers: \(error)")
        }
        
        isLoading = false
    }
    
    func addMarker(_ marker: Marker) async {
        isLoading = true
        error = nil
        
        do {
            try await db.collection(markersCollection)
                .document(marker.id.uuidString)
                .setData(from: marker)
            
            // Add to local array
            markers.insert(marker, at: 0)
            print("✅ Added marker to Firebase: \(marker.id)")
            
        } catch {
            self.error = "Failed to add marker: \(error.localizedDescription)"
            print("❌ Error adding marker: \(error)")
        }
        
        isLoading = false
    }
    
    func updateMarker(_ marker: Marker) async {
        isLoading = true
        error = nil
        
        do {
            try await db.collection(markersCollection)
                .document(marker.id.uuidString)
                .setData(from: marker, merge: true)
            
            // Update local array
            if let index = markers.firstIndex(where: { $0.id == marker.id }) {
                markers[index] = marker
            }
            print("✅ Updated marker in Firebase: \(marker.id)")
            
        } catch {
            self.error = "Failed to update marker: \(error.localizedDescription)"
            print("❌ Error updating marker: \(error)")
        }
        
        isLoading = false
    }
    
    func deleteMarker(_ markerId: UUID) async {
        isLoading = true
        error = nil
        
        do {
            try await db.collection(markersCollection)
                .document(markerId.uuidString)
                .delete()
            
            // Remove from local array
            markers.removeAll { $0.id == markerId }
            print("✅ Deleted marker from Firebase: \(markerId)")
            
        } catch {
            self.error = "Failed to delete marker: \(error.localizedDescription)"
            print("❌ Error deleting marker: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Real-time Listeners
    
    func startListening() {
        db.collection(markersCollection)
            .order(by: "created_at", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    Task { @MainActor in
                        self.error = "Real-time listener error: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let snapshot = snapshot else { return }
                
                do {
                    let updatedMarkers = try snapshot.documents.compactMap { document in
                        try document.data(as: Marker.self)
                    }
                    
                    Task { @MainActor in
                        self.markers = updatedMarkers
                        print("🔄 Real-time update: \(updatedMarkers.count) markers")
                    }
                    
                } catch {
                    Task { @MainActor in
                        self.error = "Failed to decode real-time update: \(error.localizedDescription)"
                    }
                }
            }
    }
    
    func clearError() {
        error = nil
    }
}
```

### 3.3 Update Marker Model for Firebase

Update your `Marker` model to be Firestore-compatible:

```swift
import Foundation
import CoreLocation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Marker: Identifiable, Codable {
    @DocumentID var id: String?
    let latitude: Double
    let longitude: Double
    let status: MarkerStatus
    let salesman_name: String
    let team_number: Int
    @ServerTimestamp var created_at: Timestamp?
    
    // Computed properties
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var createdDate: Date {
        created_at?.dateValue() ?? Date()
    }
    
    init(coordinate: CLLocationCoordinate2D, status: MarkerStatus, salesman_name: String, team_number: Int) {
        self.id = UUID().uuidString
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.status = status
        self.salesman_name = salesman_name
        self.team_number = team_number
        self.created_at = nil // Will be set by server
    }
}

enum MarkerStatus: String, Codable, CaseIterable {
    case sold = "sold"
    case notInterested = "no_interest"
    case notHome = "not_home"
    
    var displayName: String {
        switch self {
        case .sold: return "Sold"
        case .notInterested: return "Not Interested"
        case .notHome: return "Not Home"
        }
    }
    
    var color: Color {
        switch self {
        case .sold: return .green
        case .notInterested: return .red
        case .notHome: return .orange
        }
    }
}
```

### 3.4 Update MarkerViewModel

Replace the current MarkerViewModel Firebase service integration:

```swift
// At the top of MarkerViewModel.swift
private let firebaseService = FirebaseService.shared

// In init():
Task {
    await firebaseService.fetchMarkers()
    firebaseService.startListening() // Enable real-time updates
}

// Update methods to use Firebase:
func fetchMarkers() async {
    await firebaseService.fetchMarkers()
    markers = firebaseService.markers
}

func placeMarker(at coordinate: CLLocationCoordinate2D, status: String, name: String, team: Int) async {
    let markerStatus: MarkerStatus = // ... existing conversion logic
    let newMarker = Marker(coordinate: coordinate, status: markerStatus, salesman_name: name, team_number: team)
    await firebaseService.addMarker(newMarker)
}

func deleteMarker(_ marker: Marker) async {
    guard let markerId = UUID(uuidString: marker.id ?? "") else { return }
    await firebaseService.deleteMarker(markerId)
}
```

---

## 🔒 **Step 4: Firestore Security Rules**

In Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to markers collection
    match /markers/{document} {
      allow read, write: if true; // Change this for production
    }
  }
}
```

**For production, implement proper authentication:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /markers/{document} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 📱 **Step 5: Test Firebase Integration**

### 5.1 Build and Run
1. Clean build folder
2. Build and run your app
3. Check Xcode console for Firebase connection logs

### 5.2 Verify in Firebase Console
1. Go to Firestore Database in Firebase Console
2. You should see a `markers` collection appear when you add markers
3. Real-time updates should work automatically

---

## 🚀 **Step 6: Advanced Features**

### 6.1 Authentication (Optional)
```swift
// Add to FirebaseService
func signInAnonymously() async {
    do {
        let result = try await Auth.auth().signInAnonymously()
        print("Signed in as: \(result.user.uid)")
    } catch {
        print("Authentication error: \(error)")
    }
}
```

### 6.2 Offline Support
Firebase automatically provides offline support! No additional code needed.

### 6.3 Batch Operations
```swift
func batchAddMarkers(_ markers: [Marker]) async {
    let batch = db.batch()
    
    for marker in markers {
        let ref = db.collection(markersCollection).document()
        try batch.setData(from: marker, forDocument: ref)
    }
    
    try await batch.commit()
}
```

---

## ✅ **Migration Checklist**

- [ ] Remove Supabase package from Xcode
- [ ] Create Firebase project
- [ ] Add GoogleService-Info.plist
- [ ] Install Firebase SDK
- [ ] Update App Delegate
- [ ] Create FirebaseService
- [ ] Update Marker model
- [ ] Update MarkerViewModel
- [ ] Set Firestore security rules
- [ ] Test real-time functionality
- [ ] Verify offline support

---

## 🐛 **Troubleshooting**

### Common Issues:

1. **"No such module 'FirebaseCore'"**
   - Make sure Firebase packages are properly added
   - Clean and rebuild

2. **"GoogleService-Info.plist not found"**
   - Ensure the file is in your project root
   - Check target membership

3. **Permission denied errors**
   - Check Firestore security rules
   - Ensure proper authentication

4. **Real-time not working**
   - Check internet connection
   - Verify Firestore rules allow read access

---

## 📚 **Additional Resources**

- [Firebase iOS Documentation](https://firebase.google.com/docs/ios/setup)
- [Firestore Getting Started](https://firebase.google.com/docs/firestore/quickstart)
- [Firebase Auth](https://firebase.google.com/docs/auth/ios/anonymous-auth)
- [SwiftUI + Firebase Tutorial](https://firebase.google.com/codelabs/firebase-ios-swiftui)

---

**Firebase offers better real-time capabilities, offline support, and scalability compared to Supabase!** 🚀 