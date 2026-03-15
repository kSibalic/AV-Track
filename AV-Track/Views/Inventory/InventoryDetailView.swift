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
    @State private var showingPrintSheet = false
    @State private var newLocationName = ""
    @State private var newLocationQuantity = 1

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                
                VStack(spacing: 20) {
                    locationsSection
                    dependenciesSection
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Item", systemImage: "pencil")
                    }

                    Button {
                        showingPrintSheet = true
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
        .sheet(isPresented: $showingPrintSheet) {
            PrintLabelView(item: item)
        }
        .sheet(isPresented: $showingAddLocation) {
            NavigationStack {
                Form {
                    Picker("Location", selection: $newLocationName) {
                        ForEach(AppLocations.all, id: \.self) { loc in
                            Text(loc).tag(loc)
                        }
                    }
                    Stepper("Quantity: \(newLocationQuantity)", value: $newLocationQuantity, in: 1...999)
                }
                .navigationTitle("Add Location")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddLocation = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addLocation()
                            showingAddLocation = false
                        }
                    }
                }
            }
            .presentationDetents([.fraction(0.3)])
        }
    }

    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.title2.bold())
                    Text(item.sku)
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if item.isSerialized {
                    Label("Serialized", systemImage: "number.square.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                } else {
                    Label("Bulk", systemImage: "cube.box.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("CATEGORY")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Text(item.category)
                        .font(.headline)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(alignment: .leading) {
                    Text("TOTAL STOCK")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Text("\(item.totalStock)")
                        .font(.headline)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        .padding(.top)
        .padding(.horizontal)
    }

    private var locationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Locations")
                    .font(.headline)
                Spacer()
                Button {
                    newLocationName = AppLocations.all.first ?? "Warehouse"
                    newLocationQuantity = 1
                    showingAddLocation = true
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                }
            }
            
            if item.locations.isEmpty {
                ContentUnavailableView(
                    "No Locations",
                    systemImage: "mappin.slash",
                    description: Text("Add a location to track where this item is stored.")
                )
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(item.locations.enumerated()), id: \.element.id) { index, location in
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(Color.accentColor)
                                .font(.title3)
                            
                            Text(location.locationName)
                                .font(.body.weight(.medium))
                            
                            Spacer()
                            
                            Text("×\(location.quantity)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.secondary)
                                
                            Button(role: .destructive) {
                                deleteLocation(location)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .padding(.leading, 8)
                        }
                        .padding()
                        
                        if index < item.locations.count - 1 {
                            Divider()
                                .padding(.leading, 46)
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.02), radius: 5, y: 2)
            }
        }
    }

    private var dependenciesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Required Accessories")
                .font(.headline)
                
            if item.dependencies.isEmpty {
                ContentUnavailableView(
                    "No Dependencies",
                    systemImage: "puzzlepiece",
                    description: Text("No required accessories configured.")
                )
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(item.dependencies.enumerated()), id: \.element.id) { index, dependency in
                        HStack {
                            Image(systemName: "link")
                                .foregroundStyle(.secondary)
                                .font(.title3)
                                
                            VStack(alignment: .leading, spacing: 2) {
                                if let child = dependency.childItem {
                                    Text(child.name)
                                        .font(.body.weight(.medium))
                                }
                                if !dependency.note.isEmpty {
                                    Text(dependency.note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        
                        if index < item.dependencies.count - 1 {
                            Divider()
                                .padding(.leading, 46)
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.02), radius: 5, y: 2)
            }
        }
    }

    private func addLocation() {
        guard !newLocationName.isEmpty else { return }
        
        item.totalStock += newLocationQuantity
        let itemPayload: [String: Any] = ["id": item.id.uuidString, "total_stock": item.totalStock]
        
        if let itemData = try? JSONSerialization.data(withJSONObject: itemPayload) {
            modelContext.insert(SyncMutation(entityType: "InventoryItem", entityId: item.id, action: .update, payload: itemData))
        }
        
        if let existingLocation = item.locations.first(where: { $0.locationName == newLocationName }) {
            existingLocation.quantity += newLocationQuantity
            existingLocation.lastUpdated = Date()
            
            let locPayload: [String: Any] = [
                "id": existingLocation.id.uuidString,
                "item_id": item.id.uuidString,
                "location_name": newLocationName,
                "quantity": existingLocation.quantity,
                "last_updated": ISO8601DateFormatter().string(from: existingLocation.lastUpdated)
            ]
            
            if let data = try? JSONSerialization.data(withJSONObject: locPayload) {
                modelContext.insert(SyncMutation(entityType: "ItemLocation", entityId: existingLocation.id, action: .update, payload: data))
            }
        } else {
            let location = ItemLocation(locationName: newLocationName, quantity: newLocationQuantity, item: item)
            modelContext.insert(location)
            
            let locPayload: [String: Any] = [
                "id": location.id.uuidString,
                "item_id": item.id.uuidString,
                "location_name": newLocationName,
                "quantity": newLocationQuantity,
                "last_updated": ISO8601DateFormatter().string(from: location.lastUpdated)
            ]
            
            if let data = try? JSONSerialization.data(withJSONObject: locPayload) {
                modelContext.insert(SyncMutation(entityType: "ItemLocation", entityId: location.id, action: .create, payload: data))
            }
        }
        
        try? modelContext.save()
        Task { await SyncEngine.shared.syncNow(modelContext: modelContext) }
    }

    private func deleteLocation(_ location: ItemLocation) {
        item.totalStock = max(0, item.totalStock - location.quantity)
        let itemPayload: [String: Any] = ["id": item.id.uuidString, "total_stock": item.totalStock]
        
        if let itemData = try? JSONSerialization.data(withJSONObject: itemPayload) {
            modelContext.insert(SyncMutation(entityType: "InventoryItem", entityId: item.id, action: .update, payload: itemData))
        }
        
        let mutation = SyncMutation(
            entityType: "ItemLocation",
            entityId: location.id,
            action: .delete,
            payload: Data()
        )
        modelContext.insert(mutation)
        modelContext.delete(location)
        
        try? modelContext.save()
        Task { await SyncEngine.shared.syncNow(modelContext: modelContext) }
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
