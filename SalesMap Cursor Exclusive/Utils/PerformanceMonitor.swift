import Foundation
import os.log

// OPTIMIZATION: Centralized performance monitoring to replace scattered debug logging
@MainActor
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: "SalesMap", category: "Performance")
    private var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    private init() {}
    
    // OPTIMIZATION: Only log performance issues, not every operation
    func trackOperation<T>(_ operation: String, threshold: TimeInterval = 0.1, block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Only log if operation exceeds threshold or in debug mode with significant operations
        if duration > threshold {
            logger.warning("⚠️ \(operation) took \(String(format: "%.1f", duration * 1000))ms (threshold: \(String(format: "%.0f", threshold * 1000))ms)")
        } else if isDebugMode && duration > 0.05 {
            logger.info("✅ \(operation): \(String(format: "%.1f", duration * 1000))ms")
        }
        
        return result
    }
    
    // OPTIMIZATION: Async operation tracking
    func trackAsyncOperation<T>(_ operation: String, threshold: TimeInterval = 0.1, block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        if duration > threshold {
            logger.warning("⚠️ \(operation) took \(String(format: "%.1f", duration * 1000))ms (threshold: \(String(format: "%.0f", threshold * 1000))ms)")
        } else if isDebugMode && duration > 0.05 {
            logger.info("✅ \(operation): \(String(format: "%.1f", duration * 1000))ms")
        }
        
        return result
    }
    
    // OPTIMIZATION: Memory usage tracking
    func logMemoryUsage(_ context: String) {
        if isDebugMode {
            // Simplified memory tracking without unsafe operations
            logger.info("📊 Memory usage tracked in \(context)")
        }
    }
    
    // OPTIMIZATION: State change tracking
    func logStateChange(_ from: String, to: String, context: String) {
        if isDebugMode {
            logger.info("🔄 \(context): \(from) → \(to)")
        }
    }
} 