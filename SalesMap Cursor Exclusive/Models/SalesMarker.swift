import Foundation
import CoreLocation

struct SalesMarker: Codable, Identifiable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let status: MarkerStatus
    let timestamp: Date
    let salesmanName: String
    let teamNumber: Int
    let createdAt: Date?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Custom coding keys to match database schema
    enum CodingKeys: String, CodingKey {
        case id
        case latitude
        case longitude
        case status
        case timestamp
        case salesmanName = "salesman_name"
        case teamNumber = "team_number"
        case createdAt = "created_at"
    }
    
    init(coordinate: CLLocationCoordinate2D, status: MarkerStatus, salesmanName: String, teamNumber: Int) {
        self.id = UUID()
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.status = status
        self.timestamp = Date()
        self.salesmanName = salesmanName
        self.teamNumber = teamNumber
        self.createdAt = nil // Will be set by database
    }
    
    // Custom decoder to handle database response format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        status = try container.decode(MarkerStatus.self, forKey: .status)
        
        // Handle timestamp - Database returns ISO8601 strings
        if let timestampString = try? container.decode(String.self, forKey: .timestamp) {
            let formatter = ISO8601DateFormatter()
            timestamp = formatter.date(from: timestampString) ?? Date()
        } else {
            timestamp = try container.decode(Date.self, forKey: .timestamp)
        }
        
        salesmanName = try container.decode(String.self, forKey: .salesmanName)
        teamNumber = try container.decode(Int.self, forKey: .teamNumber)
        
        // Handle optional created_at field
        if let createdAtString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            createdAt = formatter.date(from: createdAtString)
        } else {
            createdAt = try? container.decode(Date.self, forKey: .createdAt)
        }
    }
    
    // Custom encoder for database
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(status, forKey: .status)
        
        // Encode timestamp as ISO8601 string for database
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: timestamp), forKey: .timestamp)
        
        try container.encode(salesmanName, forKey: .salesmanName)
        try container.encode(teamNumber, forKey: .teamNumber)
        
        if let createdAt = createdAt {
            try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
        }
    }
} 