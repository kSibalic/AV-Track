//
//  InventoryItem.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 02.03.2026..
//

import Foundation
import SwiftData

@Model
final class InventoryItem {
    
    #Unique<InventoryItem>([\.sku])

    @Attribute(.unique)
    var sku: String
    
    var id: UUID
    var name: String
    var isSerialized: Bool
    var category: String
    var totalStock: Int
    
    @Relationship(deleteRule: .cascade, inverse: \ItemLocation.item)
    var locations: [ItemLocation] = []
    
    @Relationship(deleteRule: .cascade, inverse: \ItemDependency.parentItem)
    var dependencies: [ItemDependency] = []
    
    @Relationship(deleteRule: .cascade, inverse: \ManifestItem.item)
    var manifestItems: [ManifestItem] = []
    
    init(
        sku: String,
        name: String,
        isSerialized: Bool,
        category: String,
        totalStock: Int
    ) {
        self.id = UUID()
        self.sku = sku
        self.name = name
        self.isSerialized = isSerialized
        self.category = category
        self.totalStock = totalStock
    }
}
