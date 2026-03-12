//
//  InventoryDetailView.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 04.03.2026..
//

import SwiftUI
import SwiftData

struct InventoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: InventoryItem

    @State private var showingEditSheet = false
    @State private var showingAddLocation = false
    @State private var newLocationName = ""
    @State private var newLocationQuantity = 1

    var body: some View {
        List {
            overviewSection
            locationsSection
            dependenciesSection
        }
        .navigationTitle(item.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Item", systemImage: "pencil")
                    }

                    Button {
                        // TODO: Set up wiring
                    } label: {
                        Label("Print Label", systemImage: "printer.fill")
                    }
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                ItemFormView(mode: .edit(item))
            }
        }
        .alert("Add Location", isPresented: $showingAddLocation) {
            TextField("Location name", text: $newLocationName)
            TextField("Quantity", value: $newLocationQuantity, format: .number)
            Button("Add") {
                addLocation()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter the location name and quantity for this item.")
        }
    }

    private var overviewSection: some View {
        Section("Overview") {
            LabeledContent("SKU") {
                Label(item.sku, systemImage: "barcode")
                    .font(.body.monospaced())
            }

            LabeledContent("Category", value: item.category)

            LabeledContent("Type") {
                if item.isSerialized {
                    Label("Serialized", systemImage: "number")
                        .foregroundStyle(.blue)
                } else {
                    Label("Bulk", systemImage: "cube.box.fill")
                        .foregroundStyle(.orange)
                }
            }

            LabeledContent("Total Stock", value: "\(item.totalStock)")
        }
    }

    private var locationsSection: some View {
        Section {
            if item.locations.isEmpty {
                ContentUnavailableView(
                    "No Locations",
                    systemImage: "mappin.slash",
                    description: Text("Add a location to track where this item is stored.")
                )
            } else {
                ForEach(item.locations) { location in
                    HStack {
                        Label(location.locationName, systemImage: "mappin.and.ellipse")

                        Spacer()

                        Text("×\(location.quantity)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
                .onDelete(perform: deleteLocations)
            }
        } header: {
            HStack {
                Text("Locations")
                Spacer()
                Button {
                    newLocationName = ""
                    newLocationQuantity = 1
                    showingAddLocation = true
                } label: {
                    Label("Add", systemImage: "plus.circle")
                        .font(.subheadline)
                }
            }
        }
    }

    private var dependenciesSection: some View {
        Section("Required Accessories") {
            if item.dependencies.isEmpty {
                ContentUnavailableView(
                    "No Dependencies",
                    systemImage: "puzzlepiece",
                    description: Text("No required accessories configured for this item.")
                )
            } else {
                ForEach(item.dependencies) { dependency in
                    VStack(alignment: .leading, spacing: 4) {
                        if let child = dependency.childItem {
                            Label(child.name, systemImage: "link")
                        }
                        if !dependency.note.isEmpty {
                            Text(dependency.note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func addLocation() {
        guard !newLocationName.isEmpty else { return }
        let location = ItemLocation(
            locationName: newLocationName,
            quantity: newLocationQuantity,
            item: item
        )
        modelContext.insert(location)
    }

    private func deleteLocations(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(item.locations[index])
        }
    }
}

#Preview {
    NavigationStack {
        InventoryDetailView(
            item: InventoryItem(
                sku: "MIX-AH-SQ6",
                name: "Allen & Heath SQ6",
                isSerialized: true,
                category: "Mixer",
                totalStock: 1
            )
        )
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
