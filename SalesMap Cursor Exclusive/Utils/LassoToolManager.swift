import Foundation
import SwiftUI
import MapKit
import Combine

@MainActor
class LassoToolManager: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isActive: Bool = false
    @Published var isDrawing: Bool = false
    @Published var drawnPath: [CGPoint] = []
    @Published var selectedMarkers: [Marker] = []
    @Published var analysisResult: LassoAnalysisResult?
    @Published var showingAnalysisResults: Bool = false
    
    // MARK: - Private Properties
    
    private var currentMapRegion: MKCoordinateRegion = MKCoordinateRegion()
    private var currentScreenSize: CGSize = CGSize.zero
    
    // MARK: - Public Methods
    
    /// Activate the lasso tool - ready to start drawing
    func activateLassoTool() {
        isActive = true
        isDrawing = true // Start drawing immediately when activated
        clearPreviousSelection()
        print("🎯 LASSO: Tool activated - ready to draw")
    }
    
    /// Deactivate the lasso tool
    func deactivateLassoTool() {
        isActive = false
        isDrawing = false
        clearPreviousSelection()
        print("🎯 LASSO: Tool deactivated")
    }
    
    /// Start drawing a lasso shape (called automatically when activated)
    func startDrawing() {
        guard isActive else { return }
        isDrawing = true
        drawnPath = []
        print("🎯 LASSO: Drawing started")
    }
    
    /// Complete the lasso drawing and analyze markers
    func completeLassoPath(
        _ path: [CGPoint],
        markers: [Marker],
        mapRegion: MKCoordinateRegion,
        screenSize: CGSize
    ) {
        guard isActive && !path.isEmpty else { 
            print("🎯 LASSO: Cannot complete - tool inactive or empty path")
            return 
        }
        
        print("🎯 LASSO: Completing path with \(path.count) points")
        
        // Auto-close polygon if near starting point
        var finalPath = path
        if path.count > 3 {
            let startPoint = path.first!
            let endPoint = path.last!
            let distance = sqrt(pow(startPoint.x - endPoint.x, 2) + pow(startPoint.y - endPoint.y, 2))
            
            // If end is within 50 pixels of start, auto-close
            if distance < 50 {
                finalPath.append(startPoint)
                print("🎯 LASSO: Auto-closed polygon (distance: \(Int(distance))px)")
            }
        }
        
        drawnPath = finalPath
        currentMapRegion = mapRegion
        currentScreenSize = screenSize
        
        // Find markers within the lasso
        selectedMarkers = LassoAnalysisEngine.findMarkersInLasso(
            markers: markers,
            lassoPath: finalPath,
            mapRegion: mapRegion,
            screenSize: screenSize
        )
        
        print("🎯 LASSO: Found \(selectedMarkers.count) markers in selection")
        
        // Analyze the selected markers
        analysisResult = LassoAnalysisEngine.analyzeSelectedMarkers(selectedMarkers)
        
        // Always show results (even if empty)
        showingAnalysisResults = true
        isDrawing = false
        
        print("🎯 LASSO: Analysis complete - showing results")
    }
    
    /// Clear the current selection and enable drawing again
    func clearSelection() {
        drawnPath = []
        selectedMarkers = []
        analysisResult = nil
        showingAnalysisResults = false
        
        // If tool is still active, enable drawing again
        if isActive {
            isDrawing = true
            print("🎯 LASSO: Selection cleared - ready to draw again")
        }
    }
    
    /// Update map region for coordinate conversions
    func updateMapRegion(_ region: MKCoordinateRegion) {
        currentMapRegion = region
    }
    
    /// Update screen size for coordinate conversions
    func updateScreenSize(_ size: CGSize) {
        currentScreenSize = size
    }
    
    /// Check if a marker is currently selected by the lasso
    func isMarkerSelected(_ marker: Marker) -> Bool {
        return selectedMarkers.contains { $0.id == marker.id }
    }
    
    /// Get display path for showing the completed lasso selection
    func getDisplayPath() -> [CGPoint] {
        return drawnPath
    }
    
    /// Dismiss analysis results
    func dismissAnalysisResults() {
        showingAnalysisResults = false
    }
    
    // MARK: - Private Methods
    
    private func clearPreviousSelection() {
        drawnPath = []
        selectedMarkers = []
        analysisResult = nil
        showingAnalysisResults = false
    }
}

// MARK: - Lasso Tool State Extensions

extension LassoToolManager {
    
    /// Current state description for debugging
    var currentStateDescription: String {
        if !isActive {
            return "Inactive"
        } else if isDrawing {
            return "Drawing (\(drawnPath.count) points)"
        } else if !selectedMarkers.isEmpty {
            return "Selected (\(selectedMarkers.count) markers)"
        } else {
            return "Active - Ready to draw"
        }
    }
    
    /// Whether there's an active selection
    var hasActiveSelection: Bool {
        return !drawnPath.isEmpty && !selectedMarkers.isEmpty
    }
    
    /// Selection summary for quick display
    var selectionSummary: String {
        guard hasActiveSelection else { return "" }
        
        let result = analysisResult
        let sold = result?.typeBreakdown.sold ?? 0
        let notInterested = result?.typeBreakdown.notInterested ?? 0
        let notHome = result?.typeBreakdown.notHome ?? 0
        
        return "\(selectedMarkers.count) markers: \(sold) sold, \(notInterested) not interested, \(notHome) not home"
    }
} 