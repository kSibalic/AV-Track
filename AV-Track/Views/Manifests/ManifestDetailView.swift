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
            Section("Job Details") {
                if !manifest.location.isEmpty {
                    Label(manifest.location, systemImage: "map")
                }
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
        }
        .sheet(isPresented: $viewModel.showDependencySuggestions) {
            DependencySuggestionSheet(dependencies: viewModel.pendingSuggestions) { acceptedDependency in
                viewModel.acceptSuggestion(acceptedDependency, into: manifest, modelContext: modelContext)
            }
        }
        .sheet(isPresented: $showItemPicker) {
            NavigationStack {
                ItemPickerSheet { selectedItem, qty in
                    viewModel.addItem(selectedItem, quantity: qty, to: manifest, modelContext: modelContext)
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
    @State private var selectedItemForQuantity: InventoryItem? = nil
    @State private var quantityToAdd: Int = 1
    
    let onSelect: (InventoryItem, Int) -> Void
    
    var filteredItems: [InventoryItem] {
        if searchText.isEmpty { return allItems }
        return allItems.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.sku.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List(filteredItems) { item in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.name).font(.headline).foregroundStyle(.primary)
                        Text(item.sku).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if selectedItemForQuantity == item {
                        Button("Cancel") {
                            withAnimation {
                                selectedItemForQuantity = nil
                            }
                        }
                        .font(.caption.bold())
                        .buttonStyle(.bordered)
                        .tint(.red)
                    } else {
                        Button {
                            withAnimation {
                                selectedItemForQuantity = item
                                quantityToAdd = 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                
                if selectedItemForQuantity == item {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Stepper("Quantity: \(quantityToAdd)", value: $quantityToAdd, in: 1...max(1, item.totalStock))
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Button("Add") {
                                onSelect(item, quantityToAdd)
                                withAnimation {
                                    selectedItemForQuantity = nil
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                        Text("Max available: \(item.totalStock)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if selectedItemForQuantity != item {
                    withAnimation {
                        selectedItemForQuantity = item
                        quantityToAdd = 1
                    }
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
