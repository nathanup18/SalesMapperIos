import SwiftUI

struct LassoToolButton: View {
    let isActive: Bool
    let isDrawing: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            ZStack {
                // Background circle
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 56, height: 56)
                    .shadow(
                        color: isActive ? .black.opacity(0.4) : .black.opacity(0.2), 
                        radius: isActive ? 6 : 4, 
                        x: 0, 
                        y: isActive ? 3 : 2
                    )
                
                // Icon
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(iconColor)
                
                // Active indicator - thin white border with no gap
                if isActive {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 56, height: 56) // Same size as button, no gap
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(1.0) // Always fully opaque
        .disabled(isDrawing)
    }
    
    private var backgroundColor: Color {
        if isActive {
            return Color.black // Black background when active (no blue)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var iconColor: Color {
        if isDrawing {
            return .white
        } else if isActive {
            return .white // White icon when active - ensures visibility
        } else {
            return .primary
        }
    }
    
    private var iconName: String {
        // Always use lasso icon - no pencil icon
        return "lasso"
    }
} 