//
//  TransferViewModel.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 14.03.2026..
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class TransferViewModel {
    var destinationLocation: String = "Van"
    var activeManifest: JobManifest?
    var transferHistory: [TransferRecord] = []
    var pendingBulkItem: InventoryItem?
    var showQuantityPicker = false
    var scanAlertMessage: String?
    var showScanAlert = false
    
    struct TransferRecord: Identifiable {
        let id = UUID()
        let item: InventoryItem
        let quantity: Int
        let timestamp = Date()
        let success: Bool
        let message: String
    }
    
    func handleScan(sku rawSKU: String, modelContext: ModelContext) {
        let sku = rawSKU.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let descriptor = FetchDescriptor<InventoryItem>(predicate: #Predicate { $0.sku == sku })
        guard let items = try? modelContext.fetch(descriptor), let item = items.first else {
            addHistory(item: nil, quantity: 0, success: false, message: "Item not found: \(sku)")
            return
        }
        
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        
        if let manifest = activeManifest {
            let isInManifest = manifest.items.contains(where: { $0.item?.id == item.id })
            if !isInManifest {
                scanAlertMessage = "This item \(item.name) isn't in the Packing List."
                showScanAlert = true
                #if os(iOS)
                generator.notificationOccurred(.error)
                #endif
                return
            }
        }
        
        if item.isSerialized {
            performTransfer(item: item, quantity: 1, modelContext: modelContext)
        } else {
            pendingBulkItem = item
            showQuantityPicker = true
        }
    }
    
    func performTransfer(item: InventoryItem, quantity: Int, modelContext: ModelContext) {
        guard quantity > 0 else { return }
        
        let possibleSources = item.locations.filter { $0.locationName != destinationLocation && $0.quantity > 0 }
        let source: ItemLocation
        
        if let optimalSource = possibleSources.first(where: { $0.quantity >= quantity }) ?? possibleSources.first {
            source = optimalSource
        } else {
            source = getOrCreateLocation(name: "Warehouse", for: item, modelContext: modelContext)
        }
        
        let sourceName = source.locationName
        let destination = getOrCreateLocation(name: destinationLocation, for: item, modelContext: modelContext)
        
        source.quantity -= quantity
        destination.quantity += quantity
        destination.lastUpdated = Date()
        source.lastUpdated = Date()
        
        if let manifest = activeManifest {
            if let manifestItem = manifest.items.first(where: { $0.item?.id == item.id }) {
                manifestItem.packedQuantity += quantity
                
                let manifestPayload: [String: Any] = [
                    "id": manifestItem.id.uuidString,
                    "manifest_id": manifest.id.uuidString,
                    "item_id": item.id.uuidString,
                    "quantity": manifestItem.quantity,
                    "packed_quantity": manifestItem.packedQuantity
                ]
                
                if let data = try? JSONSerialization.data(withJSONObject: manifestPayload) {
                    modelContext.insert(SyncMutation(entityType: "ManifestItem", entityId: manifestItem.id, action: .update, payload: data))
                }
            }
        }
        
        let destPayload: [String: Any] = [
            "id": destination.id.uuidString,
            "item_id": item.id.uuidString,
            "location_name": destinationLocation,
            "quantity": destination.quantity,
            "last_updated": ISO8601DateFormatter().string(from: destination.lastUpdated)
        ]
        
        if let destData = try? JSONSerialization.data(withJSONObject: destPayload) {
            modelContext.insert(SyncMutation(entityType: "ItemLocation", entityId: destination.id, action: .update, payload: destData))
        }

        let sourcePayload: [String: Any] = [
            "id": source.id.uuidString,
            "item_id": item.id.uuidString,
            "location_name": source.locationName,
            "quantity": source.quantity,
            "last_updated": ISO8601DateFormatter().string(from: source.lastUpdated)
        ]
        
        if let sourceData = try? JSONSerialization.data(withJSONObject: sourcePayload) {
            modelContext.insert(SyncMutation(entityType: "ItemLocation", entityId: source.id, action: .update, payload: sourceData))
        }
        
        try? modelContext.save()
        
        Task {
            await SyncEngine.shared.syncNow(modelContext: modelContext)
        }
        
        addHistory(item: item, quantity: quantity, success: true, message: "\(sourceName) ➔ \(destinationLocation)")
    }
    
    private func getOrCreateLocation(name: String, for item: InventoryItem, modelContext: ModelContext) -> ItemLocation {
        if let existing = item.locations.first(where: { $0.locationName == name }) {
            return existing
        } else {
            let newLocation = ItemLocation(locationName: name, quantity: 0)
            item.locations.append(newLocation)
            modelContext.insert(newLocation)
            return newLocation
        }
    }
    
    private func addHistory(item: InventoryItem?, quantity: Int, success: Bool, message: String) {
        let recordItem = item ?? InventoryItem(sku: "UNKNOWN", name: "Unknown Scan", isSerialized: false, category: "Error", totalStock: 0)

        let record = TransferRecord(item: recordItem, quantity: quantity, success: success, message: message)
        withAnimation(.spring) {
            transferHistory.insert(record, at: 0)
        }
    }
}
