import SwiftUI

public struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    public init(title: String, value: String, color: Color, icon: String) {
        self.title = title
        self.value = value
        self.color = color
        self.icon = icon
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Large colored icon circle
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: 24, weight: .bold))
                }
                
                Spacer()
                
                // Large value display
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            
            // Title with better typography
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
} 