//
//  ManifestDetailView.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 15.03.2026..
//

import SwiftUI
import SwiftData

struct ManifestDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let manifest: JobManifest
    @Bindable var viewModel: ManifestViewModel
    
    @State private var scanner = ScannerInputManager.shared
    @State private var showItemPicker = false
    
    var body: some View {
        List {
            Section("Status") {
                Picker("Job Status", selection: Bindable(manifest).status) {
                    Text("Draft").tag(ManifestStatus.draft)
                    Text("Packed").tag(ManifestStatus.packed)
                    Text("Returned").tag(ManifestStatus.returned)
                }
                .pickerStyle(.menu)
            }
            
            Section {
                Button {
                    showItemPicker = true
                } label: {
                    Label("Add by Search", systemImage: "magnifyingglass")
                }
            } header: {
                Text("Packing List")
            } footer: {
                Text("You can also use scanner to instantly add items to this manifest.")
            }
            
            Section {
                if manifest.items.isEmpty {
                    ContentUnavailableView("No Items", systemImage: "box.truck.badge.clock", description: Text("Add items to start building this manifest."))
                } else {
                    let sortedItems = manifest.items.sorted {
                        ($0.item?.name ?? "") < ($1.item?.name ?? "")
                    }
                    
                    ForEach(sortedItems) { manifestItem in
                        ManifestItemRow(manifestItem: manifestItem)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            viewModel.removeManifestItem(sortedItems[index], from: manifest, modelContext: modelContext)
                        }
                    }
                }
            }
        }
        .navigationTitle(manifest.jobName)
        .onChange(of: scanner.lastScannedSKU) { _, newSKU in
            guard let sku = newSKU else { return }
            viewModel.handleScan(sku: sku, for: manifest, modelContext: modelContext)
            scanner.lastScannedSKU = nil
        }
        .sheet(isPresented: $viewModel.showDependencySuggestions) {
            DependencySuggestionSheet(dependencies: viewModel.pendingSuggestions) { acceptedDependency in
                viewModel.acceptSuggestion(acceptedDependency, into: manifest, modelContext: modelContext)
            }
        }
        .sheet(isPresented: $showItemPicker) {
            NavigationStack {
                ItemPickerSheet { selectedItem in
                    viewModel.addItem(selectedItem, to: manifest, modelContext: modelContext)
                    showItemPicker = false
                }
            }
        }
    }
}

struct ManifestItemRow: View {
    let manifestItem: ManifestItem
    
    var body: some View {
        HStack {
            if let item = manifestItem.item {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                    Text(item.sku)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Unknown Item")
                    .foregroundStyle(.red)
            }
            
            Spacer()
            
            Text("x\(manifestItem.quantity)")
                .font(.title3.monospacedDigit())
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct ItemPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \InventoryItem.name) private var allItems: [InventoryItem]
    
    @State private var searchText = ""
    let onSelect: (InventoryItem) -> Void
    
    var filteredItems: [InventoryItem] {
        if searchText.isEmpty { return allItems }
        return allItems.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.sku.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List(filteredItems) { item in
            Button {
                onSelect(item)
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.name).font(.headline).foregroundStyle(.primary)
                        Text(item.sku).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "plus.circle")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .navigationTitle("Select Item")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search items")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}
