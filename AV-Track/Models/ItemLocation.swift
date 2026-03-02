//
//  ItemLocation.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 02.03.2026..
//

import Foundation
import SwiftData

@Model
final class ItemLocation {
    
    var id: UUID
    var locationName: String
    var quantity: Int
    var lastUpdated: Date
    
    var item: InventoryItem?
    
    init(
        locationName: String,
        quantity: Int,
        item: InventoryItem? = nil
    ) {
        self.id = UUID()
        self.locationName = locationName
        self.quantity = quantity
        self.lastUpdated = .now
        self.item = item
    }
}
