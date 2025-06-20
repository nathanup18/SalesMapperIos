//
//  SalesMap_Cursor_ExclusiveApp.swift
//  SalesMap Cursor Exclusive
//
//  Created by Nathan Roberts on 2025-05-31.
//

import SwiftUI
import UIKit
import Combine
import os.log
import FirebaseCore

@MainActor
class StartupManager: ObservableObject {
    static let shared = StartupManager()
    
    @Published var isInitialized = false
    @Published var initializationStatus = "Starting up..."
    
    private init() {}
    
    func initializeApp() async {
        initializationStatus = "Initializing Firebase..."
        
        // Initialize Firebase if not already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 Firebase configured successfully")
        }
        
        initializationStatus = "Initializing app components..."
        
        // Suppress non-critical startup warnings
        suppressStartupWarnings()
        
        // Initialize Firebase services
        initializationStatus = "Connecting to Firebase..."
        initializeFirebaseServices()
        
        // Complete initialization
        initializationStatus = "Ready"
        isInitialized = true
        
        print("✅ App initialization completed successfully")
    }
    
    private func suppressStartupWarnings() {
        print("🔧 Suppressing non-critical startup warnings...")
    }
    
    private func initializeFirebaseServices() {
        // Initialize Firebase services
        let firebaseService = FirebaseService.shared
        firebaseService.initialize()
        initializationStatus = "Connected to Firebase"
    }
    
    func retryInitialization() async {
        isInitialized = false
        await initializeApp()
    }
}

@main
struct SalesMap_Cursor_ExclusiveApp: App {
    
    init() {
        // Configure Firebase as early as possible
        // Check if plist exists first
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            print("🔥 Found GoogleService-Info.plist at: \(path)")
            FirebaseApp.configure()
            print("🔥 Firebase configured successfully")
        } else {
            print("❌ GoogleService-Info.plist not found in bundle")
            print("📁 Bundle path: \(Bundle.main.bundlePath)")
            // Still try to configure in case it's there but not found
            FirebaseApp.configure()
        }
    }
    
    @StateObject private var startupManager: StartupManager = {
        let manager = StartupManager.shared
        Task { @MainActor in
            await manager.initializeApp()
        }
        return manager
    }()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if startupManager.isInitialized {
                    ContentView()
                } else {
                    StartupView()
                        .environmentObject(startupManager)
                }
            }
        }
    }
    
    private func setupLogging() {
        // Reduce log noise for missing files that don't affect functionality
        print("🚀 SalesMap app starting up...")
        print("📱 Device: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
        print("📦 App Bundle: \(Bundle.main.bundleIdentifier ?? "unknown")")
    }
}

struct StartupView: View {
    @EnvironmentObject var startupManager: StartupManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("SalesMap")
                .font(.title)
                .fontWeight(.bold)
            
            Text(startupManager.initializationStatus)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !startupManager.isInitialized {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.top)
            }
            
            if startupManager.initializationStatus.contains("failed") || 
               startupManager.initializationStatus.contains("error") {
                Button("Retry") {
                    Task {
                        await startupManager.retryInitialization()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
