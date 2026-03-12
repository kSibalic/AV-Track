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
    }

    @ViewBuilder
    private func destinationView(for tab: AppTab) -> some View {
        switch tab {
        case .inventory:
            InventoryListView()
        case .transfer:
            TransferPlaceholderView()
        case .manifests:
            ManifestPlaceholderView()
        case .settings:
            SettingsView()
        }
    }
}

struct TransferPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Transfer Mode",
            systemImage: "arrow.left.arrow.right",
            description: Text("Scan items to move them between locations.")
        )
        .navigationTitle("Transfer")
    }
}

struct ManifestPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Job Manifests",
            systemImage: "list.clipboard.fill",
            description: Text("Create and manage packing lists for events.")
        )
        .navigationTitle("Manifests")
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
