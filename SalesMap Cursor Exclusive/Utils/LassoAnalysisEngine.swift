import Foundation
import CoreLocation
import SwiftUI
import MapKit

// MARK: - Analysis Results Models

struct LassoAnalysisResult {
    let selectedMarkers: [Marker]
    let typeBreakdown: MarkerTypeBreakdown
    let userTimeBreakdown: UserTimeBreakdown
    let totalCount: Int
    let selectionArea: String // Area description
}

struct MarkerTypeBreakdown {
    let sold: Int
    let notInterested: Int
    let notHome: Int
    
    var total: Int {
        sold + notInterested + notHome
    }
    
    var breakdown: [(String, Int, Color)] {
        [
            ("Sold", sold, .green),
            ("Not Interested", notInterested, .red),
            ("Not Home", notHome, .orange)
        ]
    }
}

struct UserTimeBreakdown {
    let userCounts: [String: Int]
    let dailyCounts: [String: Int]
    let weeklyCounts: [String: Int]
    let teamCounts: [Int: Int]
    
    var topUsers: [(String, Int)] {
        userCounts.sorted { $0.value > $1.value }
    }
    
    var recentActivity: [(String, Int)] {
        dailyCounts.sorted { $0.key > $1.key }.prefix(7).map { ($0.key, $0.value) }
    }
}

// MARK: - Main Analysis Engine

class LassoAnalysisEngine {
    
    // MARK: - Point-in-Polygon Detection
    
    /// Ray-casting algorithm to determine if a point is inside a polygon
    static func isPointInPolygon(point: CGPoint, polygon: [CGPoint]) -> Bool {
        guard polygon.count >= 3 else { return false }
        
        let x = point.x
        let y = point.y
        var inside = false
        
        var j = polygon.count - 1
        for i in 0..<polygon.count {
            let xi = polygon[i].x
            let yi = polygon[i].y
            let xj = polygon[j].x
            let yj = polygon[j].y
            
            if ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
                inside = !inside
            }
            j = i
        }
        
        return inside
    }
    
    // MARK: - Coordinate Conversion
    
    /// Convert geographic coordinates to screen coordinates for polygon testing
    static func convertCoordinateToScreen(
        coordinate: CLLocationCoordinate2D,
        mapRegion: MKCoordinateRegion,
        screenSize: CGSize
    ) -> CGPoint {
        // Calculate the relative position within the map region
        let latRange = mapRegion.span.latitudeDelta
        let lonRange = mapRegion.span.longitudeDelta
        
        let relativeX = (coordinate.longitude - (mapRegion.center.longitude - lonRange / 2)) / lonRange
        let relativeY = ((mapRegion.center.latitude + latRange / 2) - coordinate.latitude) / latRange
        
        // Convert to screen coordinates
        let screenX = relativeX * screenSize.width
        let screenY = relativeY * screenSize.height
        
        return CGPoint(x: screenX, y: screenY)
    }
    
    // MARK: - Marker Selection
    
    /// Find all markers within the drawn lasso polygon
    static func findMarkersInLasso(
        markers: [Marker],
        lassoPath: [CGPoint],
        mapRegion: MKCoordinateRegion,
        screenSize: CGSize
    ) -> [Marker] {
        guard !lassoPath.isEmpty else { return [] }
        
        var selectedMarkers: [Marker] = []
        
        for marker in markers {
            let screenPoint = convertCoordinateToScreen(
                coordinate: marker.coordinate,
                mapRegion: mapRegion,
                screenSize: screenSize
            )
            
            if isPointInPolygon(point: screenPoint, polygon: lassoPath) {
                selectedMarkers.append(marker)
            }
        }
        
        return selectedMarkers
    }
    
    // MARK: - Data Analysis
    
    /// Analyze selected markers and generate comprehensive breakdown
    static func analyzeSelectedMarkers(_ markers: [Marker]) -> LassoAnalysisResult {
        let typeBreakdown = analyzeMarkerTypes(markers)
        let userTimeBreakdown = analyzeUserAndTime(markers)
        let area = calculateSelectionArea(markers)
        
        return LassoAnalysisResult(
            selectedMarkers: markers,
            typeBreakdown: typeBreakdown,
            userTimeBreakdown: userTimeBreakdown,
            totalCount: markers.count,
            selectionArea: area
        )
    }
    
    /// Analyze markers by type
    private static func analyzeMarkerTypes(_ markers: [Marker]) -> MarkerTypeBreakdown {
        var sold = 0
        var notInterested = 0
        var notHome = 0
        
        for marker in markers {
            switch marker.status {
            case .sold:
                sold += 1
            case .notInterested:
                notInterested += 1
            case .notHome:
                notHome += 1
            }
        }
        
        return MarkerTypeBreakdown(
            sold: sold,
            notInterested: notInterested,
            notHome: notHome
        )
    }
    
    /// Analyze markers by user and time
    private static func analyzeUserAndTime(_ markers: [Marker]) -> UserTimeBreakdown {
        var userCounts: [String: Int] = [:]
        var dailyCounts: [String: Int] = [:]
        var weeklyCounts: [String: Int] = [:]
        var teamCounts: [Int: Int] = [:]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let weekFormatter = DateFormatter()
        weekFormatter.dateFormat = "yyyy-'W'ww"
        
        for marker in markers {
            // User counts
            userCounts[marker.salesman_name, default: 0] += 1
            
            // Team counts
            teamCounts[marker.team_number, default: 0] += 1
            
            // Daily counts
            let dayKey = dateFormatter.string(from: marker.created_at)
            dailyCounts[dayKey, default: 0] += 1
            
            // Weekly counts
            let weekKey = weekFormatter.string(from: marker.created_at)
            weeklyCounts[weekKey, default: 0] += 1
        }
        
        return UserTimeBreakdown(
            userCounts: userCounts,
            dailyCounts: dailyCounts,
            weeklyCounts: weeklyCounts,
            teamCounts: teamCounts
        )
    }
    
    /// Calculate a description of the selection area
    private static func calculateSelectionArea(_ markers: [Marker]) -> String {
        guard !markers.isEmpty else { return "No area selected" }
        
        if markers.count == 1 {
            return "Single marker selected"
        }
        
        // Calculate bounding box
        let latitudes = markers.map { $0.latitude }
        let longitudes = markers.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        // Rough area calculation (not precise, but good enough for display)
        let latSpan = maxLat - minLat
        let lonSpan = maxLon - minLon
        
        // Convert to approximate meters (very rough)
        let latMeters = latSpan * 111000 // 1 degree lat ≈ 111km
        let lonMeters = lonSpan * 111000 * cos(minLat * .pi / 180)
        
        let area = latMeters * lonMeters
        
        if area < 1000 {
            return String(format: "~%.0f m² area", area)
        } else if area < 1000000 {
            return String(format: "~%.1f km² area", area / 1000000)
        } else {
            return String(format: "~%.2f km² area", area / 1000000)
        }
    }
} 