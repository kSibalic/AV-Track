//
//  ManifestItem.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 02.03.2026..
//

import Foundation
import SwiftData

@Model
final class ManifestItem {
    
    var id: UUID
    var quantity: Int
    var packedQuantity: Int
    
    var manifest: JobManifest?
    var item: InventoryItem?
    
    init(
        id: UUID = UUID(),
        quantity: Int,
        packedQuantity: Int = 0,
        manifest: JobManifest? = nil,
        item: InventoryItem? = nil
    ) {
        self.id = UUID()
        self.quantity = quantity
        self.packedQuantity = packedQuantity
        self.manifest = manifest
        self.item = item
    }
}
