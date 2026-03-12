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
    var body: some Scene {
        WindowGroup {
            ContentView()
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
