import SwiftUI

struct ErrorHandlingView: View {
    let error: String?
    let connectionStatus: String
    let onRetry: () async -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        if let error = error {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: errorIcon)
                        .foregroundColor(errorColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(errorTitle)
                            .font(.headline)
                            .foregroundColor(errorColor)
                        
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button("Retry") {
                            Task {
                                await onRetry()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Dismiss") {
                            onDismiss()
                        }
                        .buttonStyle(.plain)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(errorBackgroundColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(errorColor.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: error)
        }
    }
    
    private var errorIcon: String {
        if error?.contains("No internet") == true {
            return "wifi.slash"
        } else if error?.contains("timed out") == true {
            return "clock.badge.exclamationmark"
        } else if error?.contains("Connection lost") == true {
            return "antenna.radiowaves.left.and.right.slash"
        } else {
            return "exclamationmark.triangle"
        }
    }
    
    private var errorColor: Color {
        if error?.contains("No internet") == true || 
           error?.contains("Connection lost") == true {
            return .orange
        } else if error?.contains("timed out") == true {
            return .yellow
        } else {
            return .red
        }
    }
    
    private var errorTitle: String {
        if error?.contains("No internet") == true {
            return "No Internet Connection"
        } else if error?.contains("timed out") == true {
            return "Request Timed Out"
        } else if error?.contains("Connection lost") == true {
            return "Connection Lost"
        } else {
            return "Connection Error"
        }
    }
    
    private var errorBackgroundColor: Color {
        if error?.contains("No internet") == true || 
           error?.contains("Connection lost") == true {
            return .orange.opacity(0.1)
        } else if error?.contains("timed out") == true {
            return .yellow.opacity(0.1)
        } else {
            return .red.opacity(0.1)
        }
    }
}

struct NetworkStatusIndicator: View {
    let connectionStatus: String
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(connectionStatus)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.tertiarySystemFill))
        .cornerRadius(16)
    }
    
    private var statusColor: Color {
        switch connectionStatus.lowercased() {
        case "connected", "connected - real-time active":
            return .green
        case "disconnected", "offline mode":
            return .red
        case "connecting...", "reconnecting...":
            return .orange
        case "firebase error":
            return .red
        case "connected - no data":
            return .yellow
        default:
            return .gray
        }
    }
}

// MARK: - Preview
struct ErrorHandlingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ErrorHandlingView(
                error: "No internet connection. Marker saved locally only.",
                connectionStatus: "Disconnected",
                onRetry: { },
                onDismiss: { }
            )
            
            ErrorHandlingView(
                error: "Request timed out. Please try again.",
                connectionStatus: "Connected",
                onRetry: { },
                onDismiss: { }
            )
            
            NetworkStatusIndicator(
                connectionStatus: "Connected",
                isLoading: false
            )
            
            NetworkStatusIndicator(
                connectionStatus: "Connecting...",
                isLoading: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 