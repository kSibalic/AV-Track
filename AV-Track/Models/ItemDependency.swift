//
//  ItemDependency.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 02.03.2026..
//

import Foundation
import SwiftData

@Model
final class ItemDependency {
    
    var id: UUID
    var note: String
    
    var parentItem: InventoryItem?
    var childItem: InventoryItem?
    
    init(
        note: String = "",
        parentItem: InventoryItem? = nil,
        childItem: InventoryItem? = nil
    ) {
        self.id = UUID()
        self.note = note
        self.parentItem = parentItem
        self.childItem = childItem
    }
}
