//
//  AV_TrackApp.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 01.03.2026..
//

import SwiftUI
import SwiftData

@main
struct AV_TrackApp: App {
    @State private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            if authManager.isLoading && authManager.session == nil {
                ProgressView("Starting AV-Track")
            } else if authManager.session != nil {
                ContentView()
            } else {
                LoginView()
            }
        }
        .modelContainer(for: [
            InventoryItem.self,
            ItemLocation.self,
            ItemDependency.self,
            JobManifest.self,
            ManifestItem.self,
            SyncMutation.self
        ])
    }
}
