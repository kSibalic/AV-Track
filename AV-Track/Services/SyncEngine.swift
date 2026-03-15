//
//  SyncEngine.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 15.03.2026..
//

import Foundation
import SwiftData
import Supabase

@MainActor
@Observable
final class SyncEngine {
    static let shared = SyncEngine()
    
    var isSyncing = false
    var lastSyncError: String?
    var pendingCount = 0
    
    private var isConnected: Bool {
        NetworkMonitor.shared.isConnected
    }
    
    private init() {}
    
    func syncNow(modelContext: ModelContext) async {
        guard isConnected else { return }
        guard !isSyncing else { return }
        
        isSyncing = true
        lastSyncError = nil
        
        do {
            let descriptor = FetchDescriptor<SyncMutation>(
                predicate: #Predicate { $0.isSynced == false },
                sortBy: [SortDescriptor(\.createdAt)]
            )
            
            let mutations = try modelContext.fetch(descriptor)
            pendingCount = mutations.count
            
            if mutations.isEmpty {
                isSyncing = false
                return
            }
            

            for mutation in mutations {
                try await replay(mutation: mutation)
                
                mutation.isSynced = true
                try modelContext.save()
            }
            
            // try await fetchLatestFromServer(modelContext: modelContext)
            
            pendingCount = 0
            
        } catch {
            lastSyncError = error.localizedDescription
            print("Sync Engine Error: \(error)")
        }
        
        isSyncing = false
    }
    
    private func tableName(for entityType: String) -> String {
        switch entityType.lowercased() {
        case "inventoryitem": return "inventory_items"
        case "itemlocation": return "item_locations"
        case "itemdependency": return "item_dependencies"
        case "jobmanifest": return "job_manifests"
        case "manifestitem": return "manifest_items"
        default: return entityType.lowercased()
        }
    }

    private func replay(mutation: SyncMutation) async throws {
        let tableName = self.tableName(for: mutation.entityType)
        let table = supabase.from(tableName)

        do {
            let jsonDict = try JSONDecoder().decode([String: AnyJSON].self, from: mutation.payload)
            let action = mutation.action
            
            if action == .update {
                try await table.update(jsonDict).eq("id", value: mutation.entityId.uuidString).execute()
            } else if action == .create {
                try await table.insert(jsonDict).execute()
            } else if action == .delete {
                try await table.delete().eq("id", value: mutation.entityId.uuidString).execute()
            }
        } catch {
            print("SyncEngine Replay Error for \(mutation.entityType): \(error)")
            throw error
        }
    }
    
    func updatePendingCount(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<SyncMutation>(predicate: #Predicate { $0.isSynced == false })
        if let pending = try? modelContext.fetch(descriptor) {
            self.pendingCount = pending.count
        }
    }
}
