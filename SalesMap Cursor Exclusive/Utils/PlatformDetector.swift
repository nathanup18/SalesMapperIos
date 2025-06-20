import Foundation
import UIKit

/// Platform detection utility for determining input capabilities and device types
@MainActor
class PlatformDetector: ObservableObject {
    static let shared = PlatformDetector()
    
    @Published var currentPlatform: Platform = .unknown
    @Published var inputCapabilities: InputCapabilities = InputCapabilities()
    @Published var deviceInfo: DeviceInfo = DeviceInfo()
    
    private init() {
        detectPlatform()
        detectInputCapabilities()
        detectDeviceInfo()
        
        // Log platform detection results
        print("🖥️ PLATFORM DETECTION:")
        print("   📱 Platform: \(currentPlatform.displayName)")
        print("   👆 Touch Support: \(inputCapabilities.supportsTouch ? "✅" : "❌")")
        print("   🖱️ Mouse Support: \(inputCapabilities.supportsMouse ? "✅" : "❌")")
        print("   🖲️ Trackpad Support: \(inputCapabilities.supportsTrackpad ? "✅" : "❌")")
        print("   📏 Screen Size: \(deviceInfo.screenSize)")
        print("   🔄 Device Orientation: \(deviceInfo.orientation.displayName)")
    }
    
    // MARK: - Platform Detection
    
    private func detectPlatform() {
        #if targetEnvironment(macCatalyst)
        currentPlatform = .macCatalyst
        #elseif os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            currentPlatform = .iPad
        } else {
            currentPlatform = .iPhone
        }
        #elseif os(macOS)
        currentPlatform = .macOS
        #else
        currentPlatform = .unknown
        #endif
    }
    
    private func detectInputCapabilities() {
        var capabilities = InputCapabilities()
        
        // Touch support detection
        #if os(iOS)
        capabilities.supportsTouch = true
        capabilities.supportsMultiTouch = true
        #elseif targetEnvironment(macCatalyst)
        capabilities.supportsTouch = true
        capabilities.supportsMultiTouch = true
        capabilities.supportsMouse = true
        capabilities.supportsTrackpad = true
        #else
        capabilities.supportsTouch = false
        capabilities.supportsMultiTouch = false
        capabilities.supportsMouse = true
        capabilities.supportsTrackpad = true
        #endif
        
        // Advanced gesture support
        capabilities.supportsPinchZoom = capabilities.supportsMultiTouch
        capabilities.supportsScrollZoom = capabilities.supportsMouse || capabilities.supportsTrackpad
        capabilities.supportsRotation = capabilities.supportsMultiTouch
        
        inputCapabilities = capabilities
    }
    
    private func detectDeviceInfo() {
        var info = DeviceInfo()
        
        // Screen size detection
        let screen = UIScreen.main
        info.screenSize = screen.bounds.size
        info.screenScale = screen.scale
        info.nativeScale = screen.nativeScale
        
        // Orientation detection
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            switch windowScene.interfaceOrientation {
            case .portrait, .portraitUpsideDown:
                info.orientation = .portrait
            case .landscapeLeft, .landscapeRight:
                info.orientation = .landscape
            default:
                info.orientation = .unknown
            }
        }
        
        // Device capabilities
        info.supportsHaptics = UIDevice.current.userInterfaceIdiom != .mac
        info.supportsForceTouch = false // Would need specific detection
        
        deviceInfo = info
    }
    
    // MARK: - Public Interface
    
    func refreshDetection() {
        detectPlatform()
        detectInputCapabilities()
        detectDeviceInfo()
    }
    
    var isDesktop: Bool {
        return currentPlatform == .macOS || currentPlatform == .macCatalyst
    }
    
    var isMobile: Bool {
        return currentPlatform == .iPhone || currentPlatform == .iPad
    }
    
    var preferredZoomMethod: ZoomMethod {
        if inputCapabilities.supportsPinchZoom && isMobile {
            return .pinchToZoom
        } else if inputCapabilities.supportsScrollZoom && isDesktop {
            return .scrollZoom
        } else {
            return .buttonZoom
        }
    }
    
    func getOptimalGestureSettings() -> GestureSettings {
        var settings = GestureSettings()
        
        switch currentPlatform {
        case .iPhone:
            settings.pinchSensitivity = 1.0
            settings.scrollSensitivity = 0.0
            settings.minimumZoomScale = 0.1
            settings.maximumZoomScale = 10.0
            
        case .iPad:
            settings.pinchSensitivity = 0.8
            settings.scrollSensitivity = 0.3
            settings.minimumZoomScale = 0.05
            settings.maximumZoomScale = 15.0
            
        case .macCatalyst:
            settings.pinchSensitivity = 0.6
            settings.scrollSensitivity = 1.2
            settings.minimumZoomScale = 0.01
            settings.maximumZoomScale = 20.0
            
        case .macOS:
            settings.pinchSensitivity = 0.0
            settings.scrollSensitivity = 1.5
            settings.minimumZoomScale = 0.01
            settings.maximumZoomScale = 25.0
            
        case .unknown:
            settings = GestureSettings() // Default values
        }
        
        return settings
    }
}

// MARK: - Supporting Types

enum Platform: CaseIterable {
    case iPhone
    case iPad
    case macOS
    case macCatalyst
    case unknown
    
    var displayName: String {
        switch self {
        case .iPhone: return "iPhone"
        case .iPad: return "iPad"
        case .macOS: return "macOS"
        case .macCatalyst: return "Mac Catalyst"
        case .unknown: return "Unknown"
        }
    }
}

struct InputCapabilities {
    var supportsTouch: Bool = false
    var supportsMultiTouch: Bool = false
    var supportsMouse: Bool = false
    var supportsTrackpad: Bool = false
    var supportsPinchZoom: Bool = false
    var supportsScrollZoom: Bool = false
    var supportsRotation: Bool = false
}

struct DeviceInfo {
    var screenSize: CGSize = .zero
    var screenScale: CGFloat = 1.0
    var nativeScale: CGFloat = 1.0
    var orientation: DeviceOrientation = .unknown
    var supportsHaptics: Bool = false
    var supportsForceTouch: Bool = false
}

enum DeviceOrientation {
    case portrait
    case landscape
    case unknown
    
    var displayName: String {
        switch self {
        case .portrait: return "Portrait"
        case .landscape: return "Landscape"
        case .unknown: return "Unknown"
        }
    }
}

enum ZoomMethod {
    case pinchToZoom
    case scrollZoom
    case buttonZoom
    
    var displayName: String {
        switch self {
        case .pinchToZoom: return "Pinch to Zoom"
        case .scrollZoom: return "Scroll Zoom"
        case .buttonZoom: return "Button Zoom"
        }
    }
}

struct GestureSettings {
    var pinchSensitivity: Double = 1.0
    var scrollSensitivity: Double = 1.0
    var minimumZoomScale: Double = 0.1
    var maximumZoomScale: Double = 10.0
    var zoomAnimationDuration: Double = 0.3
    var hapticFeedbackEnabled: Bool = true
} 