//
//  ContentView.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 01.03.2026..
//

import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable, Identifiable {
    case inventory = "Inventory"
    case transfer  = "Transfer"
    case manifests = "Manifests"
    case settings  = "Settings"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .inventory: "shippingbox.fill"
        case .transfer:  "arrow.left.arrow.right"
        case .manifests: "list.clipboard.fill"
        case .settings:  "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .inventory

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.rawValue, systemImage: tab.symbol, value: tab) {
                    NavigationStack {
                        destinationView(for: tab)
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .scannerEnvironment()
    }

    @ViewBuilder
    private func destinationView(for tab: AppTab) -> some View {
        switch tab {
        case .inventory:
            InventoryListView()
        case .transfer:
            TransferView()
        case .manifests:
            ManifestListView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            InventoryItem.self,
            ItemLocation.self,
            ItemDependency.self,
            JobManifest.self,
            ManifestItem.self,
            SyncMutation.self
        ], inMemory: true)
}
