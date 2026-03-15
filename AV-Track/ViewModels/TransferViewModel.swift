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
    var sourceLocation: String = "Warehouse"
    var destinationLocation: String = "Van"
    
    var transferHistory: [TransferRecord] = []
    
    var pendingBulkItem: InventoryItem?
    var showQuantityPicker = false
    
    struct TransferRecord: Identifiable {
        let id = UUID()
        let item: InventoryItem
        let quantity: Int
        let timestamp = Date()
        let success: Bool
        let message: String
    }
    
    func handleScan(sku: String, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<InventoryItem>(predicate: #Predicate { $0.sku == sku })
        guard let items = try? modelContext.fetch(descriptor), let item = items.first else {
            addHistory(item: nil, quantity: 0, success: false, message: "Item not found: \(sku)")
            return
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
        
        let source = getOrCreateLocation(name: sourceLocation, for: item, modelContext: modelContext)
        let destination = getOrCreateLocation(name: destinationLocation, for: item, modelContext: modelContext)
        
        if source.quantity < quantity {
            addHistory(item: item, quantity: quantity, success: false, message: "Not enough stock in \(sourceLocation)")
            return
        }
        
        source.quantity -= quantity
        destination.quantity += quantity
        destination.lastUpdated = Date()
        source.lastUpdated = Date()
        
        let payload: [String: Any] = [
            "id": destination.id.uuidString,
            "item_id": item.id.uuidString,
            "location_name": destinationLocation,
            "quantity": destination.quantity,
            "last_updated": ISO8601DateFormatter().string(from: destination.lastUpdated)
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            let mutation = SyncMutation(
                entityType: "ItemLocation",
                entityId: destination.id,
                action: .update,
                payload: data
            )
            modelContext.insert(mutation)
        }
        
        try? modelContext.save()
        
        addHistory(item: item, quantity: quantity, success: true, message: "Moved to \(destinationLocation)")
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
