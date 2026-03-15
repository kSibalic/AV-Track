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
    
    private func replay(mutation: SyncMutation) async throws {
        let table = supabase.from(mutation.entityType.lowercased())
        
        guard let jsonDict = try? JSONDecoder().decode([String: AnyJSON].self, from: mutation.payload) else {
            print("Failed to decode mutation payload")
            return
        }
        
        switch mutation.action {
        case .update:
            try await table.update(jsonDict)
                .eq("id", value: mutation.entityId.uuidString)
                .execute()
            
        case .create:
            try await table.insert(jsonDict)
                .execute()
            
        case .delete:
            try await table.delete()
                .eq("id", value: mutation.entityId.uuidString)
                .execute()
        }
    }
    
    func updatePendingCount(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<SyncMutation>(predicate: #Predicate { $0.isSynced == false })
        if let pending = try? modelContext.fetch(descriptor) {
            self.pendingCount = pending.count
        }
    }
}
