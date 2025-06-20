import SwiftUI
import CoreLocation

struct LassoDrawingView: View {
    @Binding var isDrawing: Bool
    @Binding var drawnPath: [CGPoint]
    let onPathCompleted: ([CGPoint]) -> Void
    
    @State private var currentPath: [CGPoint] = []
    
    var body: some View {
        Canvas { context, size in
            // Draw the current path being drawn
            if !currentPath.isEmpty {
                var path = Path()
                path.move(to: currentPath[0])
                for point in currentPath.dropFirst() {
                    path.addLine(to: point)
                }
                
                // Draw the path with BLUE color for consistency with app theme
                context.stroke(
                    path, 
                    with: .color(.blue), 
                    style: StrokeStyle(
                        lineWidth: 3, 
                        lineCap: .round, 
                        lineJoin: .round, 
                        dash: [12, 8] // Chunky dashes - wider and longer for better visibility
                    )
                )
                
                // Draw small circles at each point for better visibility
                for point in currentPath {
                    context.fill(
                        Path(ellipseIn: CGRect(x: point.x - 1.5, y: point.y - 1.5, width: 3, height: 3)), 
                        with: .color(.blue.opacity(0.6))
                    )
                }
                
                // No preview line to cursor - only show traced path
            }
        }
        .allowsHitTesting(isDrawing)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if isDrawing {
                        let newPoint = value.location
                        
                        // Distance-based point sampling for consistent dash rendering
                        if currentPath.isEmpty || distance(from: currentPath.last!, to: newPoint) > 5 {
                            currentPath.append(newPoint)
                            print("🎯 LASSO: Drawing point \(currentPath.count): (\(Int(newPoint.x)), \(Int(newPoint.y)))")
                            
                            // Check if user connected back to starting point (auto-complete)
                            // Reduced sensitivity - need to be closer to start point
                            if currentPath.count > 15, let startPoint = currentPath.first {
                                let distanceToStart = distance(from: newPoint, to: startPoint)
                                if distanceToStart < 20 { // Reduced from 30px to 20px for less sensitive detection
                                    print("🎯 LASSO: Auto-completing - connected to start")
                                    // Complete the path immediately
                                    drawnPath = currentPath + [startPoint]
                                    onPathCompleted(currentPath + [startPoint])
                                    return
                                }
                            }
                        }
                    }
                }
                .onEnded { _ in
                    if isDrawing && currentPath.count > 2 {
                        print("🎯 LASSO: Drawing ended with \(currentPath.count) points")
                        
                        // Complete the path and notify parent
                        drawnPath = currentPath
                        onPathCompleted(currentPath)
                        
                        // Keep path visible until cleared by parent
                        // Don't clear currentPath immediately
                        print("🎯 LASSO: Path completed and sent for analysis")
                    } else if isDrawing {
                        print("🎯 LASSO: Drawing ended but not enough points (\(currentPath.count))")
                    }
                }
        )
        .onChange(of: isDrawing) { newValue in
            if !newValue {
                // Clear current path when drawing stops
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    currentPath = []
                }
                print("🎯 LASSO: Drawing stopped - path will be cleared")
            } else {
                print("🎯 LASSO: Drawing started - ready for input")
            }
        }
    }
    
    private func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        let dx = from.x - to.x
        let dy = from.y - to.y
        return sqrt(dx * dx + dy * dy)
    }
} 