import Foundation
import CoreLocation
import SwiftUI
import FirebaseFirestore

// MarkerStatus enum conforming to the requirements
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

// Firebase-compatible Marker model (without FirestoreSwift)
struct Marker: Identifiable, Codable {
    var id: String?
    let latitude: Double
    let longitude: Double
    var status: MarkerStatus
    let salesman_name: String
    let team_number: Int
    var created_at: Date
    var notes: String // NEW: Notes field for salesman comments
    
    // Custom CodingKeys for Firebase field mapping
    enum CodingKeys: String, CodingKey {
        case id
        case latitude
        case longitude
        case status
        case salesman_name
        case team_number
        case created_at
        case notes
    }
    
    // Computed properties (not encoded/decoded)
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var createdDate: Date {
        created_at
    }
    
    var displayStatus: String {
        status.displayName
    }
    
    var statusColor: Color {
        status.color
    }
    
    // Convenience initializer
    init(coordinate: CLLocationCoordinate2D, status: MarkerStatus, salesman_name: String, team_number: Int) {
        self.id = nil // Will be set by Firestore when saved
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.status = status
        self.salesman_name = salesman_name
        self.team_number = team_number
        self.created_at = Date() // Set current date/time
        self.notes = "" // Initialize notes as empty
    }
    
    // Manual Codable implementation for Firebase compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        status = try container.decode(MarkerStatus.self, forKey: .status)
        salesman_name = try container.decode(String.self, forKey: .salesman_name)
        team_number = try container.decode(Int.self, forKey: .team_number)
        
        // Handle both Timestamp and Date types from Firebase
        if let timestamp = try? container.decode(Timestamp.self, forKey: .created_at) {
            created_at = timestamp.dateValue()
        } else if let date = try? container.decode(Date.self, forKey: .created_at) {
            created_at = date
        } else {
            created_at = Date() // Fallback to current date
        }
        
        // Handle notes field (may not exist in older markers)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(status, forKey: .status)
        try container.encode(salesman_name, forKey: .salesman_name)
        try container.encode(team_number, forKey: .team_number)
        try container.encode(created_at, forKey: .created_at)
        try container.encode(notes, forKey: .notes)
    }
    
    // Date validation for development
    static func validateDateParsing() -> Bool {
        print("🔥 Firebase handles date parsing via manual Codable implementation")
        return true
    }
}

// Hashable conformance for Marker
extension Marker: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Marker, rhs: Marker) -> Bool {
        lhs.id == rhs.id
    }
} 
