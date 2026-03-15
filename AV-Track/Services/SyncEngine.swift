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
            
            // Uncommented fetchLatestFromServer
            try await fetchLatestFromServer(modelContext: modelContext)
            
            pendingCount = 0
            
        } catch {
            lastSyncError = error.localizedDescription
            print("Sync Engine Error: \(error)")
        }
        
        isSyncing = false
    }
    
    func fetchLatestFromServer(modelContext: ModelContext) async throws {
        // Fetch Inventory Items
        struct SupabaseItem: Codable {
            let id: UUID
            let sku: String
            let name: String
            let is_serialized: Bool
            let category: String
            let total_stock: Int
        }
        let items: [SupabaseItem] = try await supabase.from("inventory_items").select().execute().value
        for item in items {
            let fetchDescriptor = FetchDescriptor<InventoryItem>(predicate: #Predicate { $0.id == item.id })
            if let existing = try? modelContext.fetch(fetchDescriptor).first {
                existing.sku = item.sku
                existing.name = item.name
                existing.isSerialized = item.is_serialized
                existing.category = item.category
                existing.totalStock = item.total_stock
            } else {
                let newItem = InventoryItem(sku: item.sku, name: item.name, isSerialized: item.is_serialized, category: item.category, totalStock: item.total_stock)
                newItem.id = item.id
                modelContext.insert(newItem)
            }
        }
        
        struct SupabaseManifest: Codable {
            let id: UUID
            let job_name: String
            let location: String?
            let event_date: String
            let status: String
        }
        let manifests: [SupabaseManifest] = try await supabase.from("job_manifests").select().execute().value
        for m in manifests {
            let fetchDescriptor = FetchDescriptor<JobManifest>(predicate: #Predicate { $0.id == m.id })
            
            let status = ManifestStatus(rawValue: m.status) ?? .draft
            let date = ISO8601DateFormatter().date(from: m.event_date) ?? Date()
            
            if let existing = try? modelContext.fetch(fetchDescriptor).first {
                existing.jobName = m.job_name
                existing.location = m.location ?? ""
                existing.eventDate = date
                existing.status = status
            } else {
                let newManifest = JobManifest(jobName: m.job_name, location: m.location ?? "", eventDate: date, status: status)
                newManifest.id = m.id
                modelContext.insert(newManifest)
            }
        }
        
        struct SupabaseManifestItem: Codable {
            let id: UUID
            let manifest_id: UUID
            let item_id: UUID
            let quantity: Int
            let packed_quantity: Int
        }
        let manifestItems: [SupabaseManifestItem] = try await supabase.from("manifest_items").select().execute().value
        for mi in manifestItems {
            let fetchDescriptor = FetchDescriptor<ManifestItem>(predicate: #Predicate { $0.id == mi.id })
            if let existing = try? modelContext.fetch(fetchDescriptor).first {
                existing.quantity = mi.quantity
                existing.packedQuantity = mi.packed_quantity
            } else {
                let newItem = ManifestItem(quantity: mi.quantity, packedQuantity: mi.packed_quantity)
                newItem.id = mi.id
                modelContext.insert(newItem)
                
                if let manifest = try? modelContext.fetch(FetchDescriptor<JobManifest>(predicate: #Predicate { $0.id == mi.manifest_id })).first {
                    newItem.manifest = manifest
                    manifest.items.append(newItem)
                }
                if let inventoryItem = try? modelContext.fetch(FetchDescriptor<InventoryItem>(predicate: #Predicate { $0.id == mi.item_id })).first {
                    newItem.item = inventoryItem
                    inventoryItem.manifestItems.append(newItem)
                }
            }
        }
        
        struct SupabaseLocation: Codable {
            let id: UUID
            let item_id: UUID
            let location_name: String
            let quantity: Int
            let last_updated: String
        }
        let locations: [SupabaseLocation] = try await supabase.from("item_locations").select().execute().value
        for loc in locations {
            let fetchDescriptor = FetchDescriptor<ItemLocation>(predicate: #Predicate { $0.id == loc.id })
            let date = ISO8601DateFormatter().date(from: loc.last_updated) ?? Date()
            
            if let existing = try? modelContext.fetch(fetchDescriptor).first {
                existing.locationName = loc.location_name
                existing.quantity = loc.quantity
                existing.lastUpdated = date
            } else {
                let newLoc = ItemLocation(locationName: loc.location_name, quantity: loc.quantity)
                newLoc.id = loc.id
                newLoc.lastUpdated = date
                modelContext.insert(newLoc)
                
                if let inventoryItem = try? modelContext.fetch(FetchDescriptor<InventoryItem>(predicate: #Predicate { $0.id == loc.item_id })).first {
                    newLoc.item = inventoryItem
                    inventoryItem.locations.append(newLoc)
                }
            }
        }
        
        struct SupabaseDependency: Codable {
            let id: UUID
            let parent_item_id: UUID
            let child_item_id: UUID
        }
        let dependencies: [SupabaseDependency] = try await supabase.from("item_dependencies").select().execute().value
        for dep in dependencies {
            let fetchDescriptor = FetchDescriptor<ItemDependency>(predicate: #Predicate { $0.id == dep.id })
            
            if (try? modelContext.fetch(fetchDescriptor).first) == nil {
                let newDep = ItemDependency()
                newDep.id = dep.id
                modelContext.insert(newDep)
                
                if let parent = try? modelContext.fetch(FetchDescriptor<InventoryItem>(predicate: #Predicate { $0.id == dep.parent_item_id })).first,
                   let child = try? modelContext.fetch(FetchDescriptor<InventoryItem>(predicate: #Predicate { $0.id == dep.child_item_id })).first {
                    newDep.parentItem = parent
                    newDep.childItem = child
                    parent.dependencies.append(newDep)
                }
            }
        }
        
        try? modelContext.save()
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
                try await table.upsert(jsonDict).execute()
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
