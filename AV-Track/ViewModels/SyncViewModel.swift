//
//  SyncViewModel.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 15.03.2026..
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class SyncViewModel {
    private var syncEngine = SyncEngine.shared
    
    var isSyncing: Bool {
        syncEngine.isSyncing
    }
    
    var pendingCount: Int {
        syncEngine.pendingCount
    }
    
    var lastError: String? {
        syncEngine.lastSyncError
    }
    
    var isConnected: Bool {
        NetworkMonitor.shared.isConnected
    }
    
    func refreshPendingCount(modelContext: ModelContext) {
        syncEngine.updatePendingCount(modelContext: modelContext)
    }
    
    func forceSync(modelContext: ModelContext) async {
        await syncEngine.syncNow(modelContext: modelContext)
    }
}
