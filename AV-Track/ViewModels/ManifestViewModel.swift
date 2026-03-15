//
//  ManifestViewModel.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 15.03.2026..
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class ManifestViewModel {
    var showAddManifestForm = false
    var newManifestName = ""
    var newManifestLocation = ""
    var newManifestDate = Date()
    
    var showDependencySuggestions = false
    var pendingSuggestions: [ItemDependency] = []
    
    func createManifest(modelContext: ModelContext) {
        guard !newManifestName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let manifest = JobManifest(
            jobName: newManifestName,
            location: newManifestLocation,
            eventDate: newManifestDate,
            status: .draft
        )
        
        modelContext.insert(manifest)
        
        let payload: [String: Any] = [
            "id": manifest.id.uuidString,
            "job_name": manifest.jobName,
            "location": manifest.location,
            "event_date": ISO8601DateFormatter().string(from: manifest.eventDate),
            "status": manifest.status.rawValue
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            let mutation = SyncMutation(
                entityType: "JobManifest",
                entityId: manifest.id,
                action: .create,
                payload: data
            )
            modelContext.insert(mutation)
        }
        
        try? modelContext.save()
        
        // Auto-sync
        Task {
            await SyncEngine.shared.syncNow(modelContext: modelContext)
        }
        
        newManifestName = ""
        newManifestLocation = ""
        newManifestDate = Date()
        showAddManifestForm = false
    }
    
    func deleteManifest(_ manifest: JobManifest, modelContext: ModelContext) {
        modelContext.delete(manifest)
        try? modelContext.save()
    }
    
    func handleScan(sku: String, for manifest: JobManifest, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<InventoryItem>(predicate: #Predicate { $0.sku == sku })
        guard let items = try? modelContext.fetch(descriptor), let item = items.first else {
            return
        }
        
        addItem(item, to: manifest, modelContext: modelContext)
    }
    
    func addItem(_ item: InventoryItem, quantity: Int = 1, to manifest: JobManifest, modelContext: ModelContext) {
        if let existingManifestItem = manifest.items.first(where: { $0.item?.id == item.id }) {
            let newTotal = existingManifestItem.quantity + quantity
            existingManifestItem.quantity = min(newTotal, item.totalStock)
            createManifestItemMutation(existingManifestItem, action: .update, modelContext: modelContext)
        } else {
            let actualQuantity = min(quantity, item.totalStock)
            if actualQuantity > 0 {
                let newlyAdded = ManifestItem(quantity: actualQuantity, manifest: manifest, item: item)
                manifest.items.append(newlyAdded)
                modelContext.insert(newlyAdded)
                createManifestItemMutation(newlyAdded, action: .create, modelContext: modelContext)
            }
        }
        
        try? modelContext.save()
        Task {
            await SyncEngine.shared.syncNow(modelContext: modelContext)
        }
        checkDependencies(for: item)
    }
    
    func removeManifestItem(_ item: ManifestItem, from manifest: JobManifest, modelContext: ModelContext) {
        if let index = manifest.items.firstIndex(of: item) {
            manifest.items.remove(at: index)
        }
        
        createManifestItemMutation(item, action: .delete, modelContext: modelContext)
        modelContext.delete(item)
        try? modelContext.save()
        Task {
            await SyncEngine.shared.syncNow(modelContext: modelContext)
        }
    }
    
    private func checkDependencies(for item: InventoryItem) {
        let dependencies = item.dependencies.filter { $0.parentItem == item }
        
        if !dependencies.isEmpty {
            pendingSuggestions = dependencies
            showDependencySuggestions = true
        }
    }
    
    func acceptSuggestion(_ dependency: ItemDependency, into manifest: JobManifest, modelContext: ModelContext) {
        guard let childItem = dependency.childItem else { return }
        if let existingManifestItem = manifest.items.first(where: { $0.item == childItem }) {
            if existingManifestItem.quantity < childItem.totalStock {
                existingManifestItem.quantity += 1
                createManifestItemMutation(existingManifestItem, action: .update, modelContext: modelContext)
            }
        } else {
            if childItem.totalStock > 0 {
                let newlyAdded = ManifestItem(quantity: 1, manifest: manifest, item: childItem)
                manifest.items.append(newlyAdded)
                modelContext.insert(newlyAdded)
                createManifestItemMutation(newlyAdded, action: .create, modelContext: modelContext)
            }
        }
        
        try? modelContext.save()
        Task {
            await SyncEngine.shared.syncNow(modelContext: modelContext)
        }
    }
    
    private func createManifestItemMutation(_ manifestItem: ManifestItem, action: SyncAction, modelContext: ModelContext) {
        guard let manifest = manifestItem.manifest, let item = manifestItem.item else { return }
        
        let payload: [String: Any] = [
            "id": manifestItem.id.uuidString,
            "manifest_id": manifest.id.uuidString,
            "item_id": item.id.uuidString,
            "quantity": manifestItem.quantity
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            let mutation = SyncMutation(
                entityType: "ManifestItem",
                entityId: manifestItem.id,
                action: action,
                payload: data
            )
            modelContext.insert(mutation)
        }
    }
}
