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
    var newManifestDate = Date()
    
    var showDependencySuggestions = false
    var pendingSuggestions: [ItemDependency] = []
    
    func createManifest(modelContext: ModelContext) {
        guard !newManifestName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let manifest = JobManifest(
            jobName: newManifestName,
            eventDate: newManifestDate,
            status: .draft
        )
        
        modelContext.insert(manifest)
        try? modelContext.save()
        
        newManifestName = ""
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
    
    func addItem(_ item: InventoryItem, to manifest: JobManifest, modelContext: ModelContext) {
        if let existingManifestItem = manifest.items.first(where: { $0.item == item }) {
            existingManifestItem.quantity += 1
        } else {
            let newlyAdded = ManifestItem(quantity: 1, manifest: manifest, item: item)
            manifest.items.append(newlyAdded)
            modelContext.insert(newlyAdded)
        }
        
        try? modelContext.save()
        checkDependencies(for: item)
    }
    
    func removeManifestItem(_ item: ManifestItem, from manifest: JobManifest, modelContext: ModelContext) {
        if let index = manifest.items.firstIndex(of: item) {
            manifest.items.remove(at: index)
        }
        
        modelContext.delete(item)
        try? modelContext.save()
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
            existingManifestItem.quantity += 1
        } else {
            let newlyAdded = ManifestItem(quantity: 1, manifest: manifest, item: childItem)
            manifest.items.append(newlyAdded)
            modelContext.insert(newlyAdded)
        }
        
        try? modelContext.save()
    }
}
