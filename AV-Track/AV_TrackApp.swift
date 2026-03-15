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
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            InventoryItem.self,
            ItemLocation.self,
            ItemDependency.self,
            JobManifest.self,
            ManifestItem.self,
            SyncMutation.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Schema mismatch detected, automatically clearing local database cache...")
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-shm"))
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-wal"))
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            if authManager.isLoading && authManager.session == nil {
                ProgressView("Starting AV-Track")
            } else if authManager.session != nil {
                ContentView()
                    .task {
                        if !SyncEngine.shared.isSyncing {
                            try? await SyncEngine.shared.fetchLatestFromServer(modelContext: sharedModelContainer.mainContext)
                        }
                    }
            } else {
                LoginView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
