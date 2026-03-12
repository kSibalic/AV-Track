//
//  InventoryListView.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 04.03.2026..
//

import SwiftUI
import SwiftData

struct InventoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InventoryItem.name) private var items: [InventoryItem]

    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var showingAddItem = false

    private var categories: [String] {
        Array(Set(items.map(\.category))).sorted()
    }

    private var filteredItems: [InventoryItem] {
        items.filter { item in
            let matchesSearch = searchText.isEmpty
                || item.name.localizedCaseInsensitiveContains(searchText)
                || item.sku.localizedCaseInsensitiveContains(searchText)

            let matchesCategory = selectedCategory == nil
                || item.category == selectedCategory

            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        List {
            categoryFilterSection

            if filteredItems.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                itemsSection
            }
        }
        .navigationTitle("Inventory")
        .searchable(text: $searchText, prompt: "Search by name or SKU")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddItem = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            NavigationStack {
                ItemFormView(mode: .add)
            }
        }
    }

    @ViewBuilder
    private var categoryFilterSection: some View {
        if !categories.isEmpty {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedCategory == nil
                        ) {
                            withAnimation { selectedCategory = nil }
                        }

                        ForEach(categories, id: \.self) { category in
                            FilterChip(
                                title: category,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        }
    }

    private var itemsSection: some View {
        Section("Items (\(filteredItems.count))") {
            ForEach(filteredItems) { item in
                NavigationLink(value: item) {
                    InventoryRowView(item: item)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .navigationDestination(for: InventoryItem.self) { item in
            InventoryDetailView(item: item)
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredItems[index])
        }
    }
}

struct InventoryRowView: View {
    let item: InventoryItem

    private var locationSummary: String {
        if item.locations.isEmpty {
            return "No locations"
        }
        return item.locations
            .map { "\($0.locationName) (\($0.quantity))" }
            .joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.name)
                    .font(.headline)

                Spacer()

                Text("\(item.totalStock)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Label(item.sku, systemImage: "barcode")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if item.isSerialized {
                    Text("Serialized")
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                } else {
                    Text("Bulk")
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.12))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }

            Text(locationSummary)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    NavigationStack {
        InventoryListView()
    }
    .modelContainer(for: [
        InventoryItem.self,
        ItemLocation.self,
        ItemDependency.self,
        JobManifest.self,
        ManifestItem.self,
        SyncMutation.self
    ], inMemory: true)
}
