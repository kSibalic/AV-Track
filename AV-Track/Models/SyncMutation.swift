//
//  SyncMutation.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 02.03.2026..
//

import Foundation
import SwiftData

enum SyncAction: String, Codable {
    case create
    case update
    case delete
}

@Model
final class SyncMutation {
    
    var id: UUID
    var entityType: String
    var entityId: UUID
    var action: SyncAction
    var payload: Data
    var createdAt: Date
    var isSynced: Bool
    
    init(
        entityType: String,
        entityId: UUID,
        action: SyncAction,
        payload: Data = Data(),
        isSynced: Bool = false
    ) {
        self.id = UUID()
        self.entityType = entityType
        self.entityId = entityId
        self.action = action
        self.payload = payload
        self.createdAt = .now
        self.isSynced = isSynced
    }
}
