import Foundation
import MapKit
import UIKit

/// Comprehensive gesture manager for map interactions across all platforms
@MainActor
class MapGestureManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentZoomLevel: Double = 1.0
    @Published var isGestureActive: Bool = false
    @Published var lastGestureType: GestureType = .none
    @Published var gestureSettings: GestureSettings
    @Published var pinchScale: CGFloat = 1.0 // For debugging pinch gestures
    
    // MARK: - Private Properties
    private let platformDetector = PlatformDetector.shared
    private weak var mapView: MKMapView?
    private var initialRegion: MKCoordinateRegion?
    private var gestureStartTime: Date?
    
    // Gesture state tracking
    private var lastPinchScale: CGFloat = 1.0
    private var lastScrollDelta: CGFloat = 0.0
    private var accumulatedZoomDelta: Double = 0.0
    
    // Haptic feedback
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    // MARK: - Initialization
    
    override init() {
        self.gestureSettings = PlatformDetector.shared.getOptimalGestureSettings()
        super.init()
        
        // Prepare haptic feedback generators
        if platformDetector.deviceInfo.supportsHaptics {
            impactFeedback.prepare()
            selectionFeedback.prepare()
        }
        
        print("🎯 GESTURE MANAGER INITIALIZED:")
        print("   📱 Platform: \(platformDetector.currentPlatform.displayName)")
        print("   🔍 Preferred Zoom: \(platformDetector.preferredZoomMethod.displayName)")
        print("   👆 Pinch Sensitivity: \(gestureSettings.pinchSensitivity)")
        print("   🖱️ Scroll Sensitivity: \(gestureSettings.scrollSensitivity)")
    }
    
    // MARK: - Map View Setup
    
    func setupMapView(_ mapView: MKMapView) {
        self.mapView = mapView
        self.initialRegion = mapView.region
        
        // Configure platform-specific gestures
        configureGesturesForPlatform(mapView)
        
        print("🗺️ Map view configured for \(platformDetector.currentPlatform.displayName)")
    }
    
    private func configureGesturesForPlatform(_ mapView: MKMapView) {
        // Enable/disable built-in gestures based on platform
        switch platformDetector.currentPlatform {
        case .iPhone, .iPad:
            configureMobileGestures(mapView)
        case .macCatalyst:
            configureHybridGestures(mapView)
        case .macOS:
            configureDesktopGestures(mapView)
        case .unknown:
            configureDefaultGestures(mapView)
        }
    }
    
    private func configureMobileGestures(_ mapView: MKMapView) {
        // Ensure user interaction is enabled first
        mapView.isUserInteractionEnabled = true
        
        // Enable all touch gestures for mobile
        mapView.isZoomEnabled = true
        mapView.isPitchEnabled = false // Disable 3D for performance
        mapView.isRotateEnabled = true
        mapView.isScrollEnabled = true
        
        // Add custom pinch gesture for enhanced control using addGestureRecognizer(:)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        pinchGesture.delegate = self
        
        // Configure pinch gesture to work with map's built-in gestures
        pinchGesture.cancelsTouchesInView = false
        pinchGesture.delaysTouchesBegan = false
        pinchGesture.delaysTouchesEnded = false
        
        // CRITICAL: Add the gesture recognizer to the map view
        mapView.addGestureRecognizer(pinchGesture)
        
        print("📱 Mobile gestures configured: Enhanced pinch-to-zoom enabled")
        print("🤏 Custom pinch gesture added to map view")
        print("   - Delegate: \(String(describing: pinchGesture.delegate))")
        print("   - isEnabled: \(pinchGesture.isEnabled)")
        print("   - Total gestures on map: \(mapView.gestureRecognizers?.count ?? 0)")
    }
    
    private func configureHybridGestures(_ mapView: MKMapView) {
        // Enable both touch and mouse/trackpad gestures
        mapView.isZoomEnabled = true
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = true
        mapView.isScrollEnabled = true
        
        // Add enhanced pinch gesture for hybrid platforms
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        pinchGesture.delegate = self
        
        // Configure for hybrid touch/trackpad use
        pinchGesture.cancelsTouchesInView = false
        pinchGesture.delaysTouchesBegan = false
        pinchGesture.delaysTouchesEnded = false
        
        mapView.addGestureRecognizer(pinchGesture)
        
        // Add scroll wheel support for Mac Catalyst
        if let scrollView = mapView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.panGestureRecognizer.allowedTouchTypes = [
                NSNumber(value: UITouch.TouchType.direct.rawValue),
                NSNumber(value: UITouch.TouchType.indirect.rawValue)
            ]
        }
        
        print("🖥️📱 Hybrid gestures configured: Enhanced pinch + Scroll zoom enabled")
    }
    
    private func configureDesktopGestures(_ mapView: MKMapView) {
        // Primarily mouse/trackpad gestures
        mapView.isZoomEnabled = true
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false // Typically not needed on desktop
        mapView.isScrollEnabled = true
        
        // Enable standard zoom gestures for desktop
        mapView.gestureRecognizers?.forEach { recognizer in
            recognizer.isEnabled = true
        }
        
        print("🖥️ Desktop gestures configured: Standard zoom enabled")
    }
    
    private func configureDefaultGestures(_ mapView: MKMapView) {
        // Safe default configuration
        mapView.isZoomEnabled = true
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = true
        mapView.isScrollEnabled = true
        
        print("❓ Default gestures configured")
    }
    
    // MARK: - Pinch Gesture Handling (Mobile)
    
    @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        print("🤏 PINCH GESTURE DETECTED! State: \(gesture.state.rawValue)")
        
        guard let mapView = gesture.view as? MKMapView else { 
            print("❌ Failed to get mapView from gesture.view")
            return 
        }
        
        switch gesture.state {
        case .began:
            startGesture(.pinch)
            pinchScale = gesture.scale
            print("🤏 Pinch gesture began with scale: \(gesture.scale)")
            
        case .changed:
            // Apply the current scale factor to the map's transform
            // Following Apple's recommended approach
            print("🤏 Pinch gesture changed - scale: \(gesture.scale)")
            
            // Update published property for UI feedback
            pinchScale = gesture.scale
            
            // Apply scale to the map view's transform
            mapView.transform = mapView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            
            // Reset the scale factor to 1.0 to get incremental changes
            gesture.scale = 1.0
            
            // Haptic feedback for pinch gestures
            if gestureSettings.hapticFeedbackEnabled && platformDetector.deviceInfo.supportsHaptics {
                impactFeedback.impactOccurred()
            }
            
            print("🤏 Transform applied - new transform: \(mapView.transform)")
            
        case .ended, .cancelled:
            endGesture()
            pinchScale = 1.0 // Reset scale
            print("🤏 Pinch gesture ended")
            
        default:
            break
        }
    }
    
    // MARK: - Scroll Gesture Handling (Desktop)
    
    func handleScrollGesture(_ delta: CGFloat, at location: CGPoint, in mapView: MKMapView) {
        guard platformDetector.inputCapabilities.supportsScrollZoom else {
            print("⚠️ Scroll zoom not supported on this platform")
            return
        }
        
        startGesture(.scroll)
        
        // Convert scroll delta to zoom delta
        let zoomDelta = Double(delta) * gestureSettings.scrollSensitivity * 0.01
        
        // Apply zoom centered on cursor/touch location
        applyZoomDelta(zoomDelta, to: mapView, centeredAt: location, animated: false)
        
        // Auto-end gesture after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.endGesture()
        }
        
        print("🖱️ Scroll zoom: delta=\(String(format: "%.2f", zoomDelta))")
    }
    
    // MARK: - Zoom Application
    
    private func applyZoomDelta(_ delta: Double, to mapView: MKMapView, centeredAt location: CGPoint? = nil, animated: Bool = true) {
        let currentSpan = mapView.region.span
        let currentZoom = log2(360.0 / Double(currentSpan.longitudeDelta))
        let newZoom = currentZoom + delta
        
        // Clamp zoom level to settings
        let clampedZoom = max(gestureSettings.minimumZoomScale, 
                             min(gestureSettings.maximumZoomScale, newZoom))
        
        // Calculate new span
        let newLongitudeDelta = 360.0 / pow(2.0, clampedZoom)
        let newLatitudeDelta = newLongitudeDelta * (currentSpan.latitudeDelta / currentSpan.longitudeDelta)
        
        let newSpan = MKCoordinateSpan(
            latitudeDelta: newLatitudeDelta,
            longitudeDelta: newLongitudeDelta
        )
        
        // Determine center point
        var newCenter = mapView.region.center
        if let location = location {
            // Zoom toward the gesture location
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            newCenter = coordinate
        }
        
        let newRegion = MKCoordinateRegion(center: newCenter, span: newSpan)
        
        // Apply the new region
        if animated {
            UIView.animate(withDuration: gestureSettings.zoomAnimationDuration) {
                mapView.setRegion(newRegion, animated: false)
            }
        } else {
            mapView.setRegion(newRegion, animated: false)
        }
        
        // Update current zoom level
        currentZoomLevel = clampedZoom
        accumulatedZoomDelta += delta
        
        // Log significant zoom changes
        if abs(accumulatedZoomDelta) > 0.5 {
            print("🔍 Zoom level: \(String(format: "%.2f", currentZoomLevel)) (delta: \(String(format: "%.2f", accumulatedZoomDelta)))")
            accumulatedZoomDelta = 0.0
        }
    }
    
    // MARK: - Gesture State Management
    
    private func startGesture(_ type: GestureType) {
        isGestureActive = true
        lastGestureType = type
        gestureStartTime = Date()
        
        // Prepare haptic feedback
        if gestureSettings.hapticFeedbackEnabled && platformDetector.deviceInfo.supportsHaptics {
            selectionFeedback.selectionChanged()
        }
        
        print("🎯 Gesture started: \(type.displayName)")
    }
    
    private func endGesture() {
        let gestureDuration = gestureStartTime?.timeIntervalSinceNow ?? 0
        
        isGestureActive = false
        
        print("🎯 Gesture ended: \(lastGestureType.displayName) (duration: \(String(format: "%.2f", abs(gestureDuration)))s)")
        
        lastGestureType = .none
        gestureStartTime = nil
        accumulatedZoomDelta = 0.0
    }
    
    // MARK: - Public Interface
    
    func resetZoom(animated: Bool = true) {
        guard let mapView = mapView, let initialRegion = initialRegion else { return }
        
        if animated {
            UIView.animate(withDuration: gestureSettings.zoomAnimationDuration) {
                mapView.setRegion(initialRegion, animated: false)
            }
        } else {
            mapView.setRegion(initialRegion, animated: false)
        }
        
        currentZoomLevel = 1.0
        print("🔄 Zoom reset to initial level")
    }
    
    func zoomIn(animated: Bool = true) {
        guard let mapView = mapView else { return }
        applyZoomDelta(1.0, to: mapView, animated: animated)
    }
    
    func zoomOut(animated: Bool = true) {
        guard let mapView = mapView else { return }
        applyZoomDelta(-1.0, to: mapView, animated: animated)
    }
    
    func updateGestureSettings(_ newSettings: GestureSettings) {
        gestureSettings = newSettings
        print("⚙️ Gesture settings updated")
    }
}

// MARK: - UIGestureRecognizerDelegate

extension MapGestureManager: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow simultaneous recognition with map's built-in gestures
        // This is crucial for pinch gestures to work properly with MapKit
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Handle both direct touches (finger) and indirect touches (trackpad)
        return touch.type == .direct || touch.type == .indirect
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Don't require other gestures to fail - allow concurrent recognition
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Don't require this gesture to fail for others - allow concurrent recognition
        return false
    }
}

// MARK: - Supporting Types

enum GestureType {
    case none
    case pinch
    case scroll
    case button
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .pinch: return "Pinch"
        case .scroll: return "Scroll"
        case .button: return "Button"
        }
    }
} 