//
//  ItemFormView.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 04.03.2026..
//

import SwiftUI
import SwiftData

struct ItemFormView: View {
    enum Mode {
        case add
        case edit(InventoryItem)

        var title: String {
            switch self {
            case .add: "Add Item"
            case .edit: "Edit Item"
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mode: Mode

    @State private var sku = ""
    @State private var name = ""
    @State private var isSerialized = true
    @State private var category = ""
    @State private var totalStock = 1

    private let suggestedCategories = [
        "Speakers", "Microphones", "Cables", "Lighting",
        "Staging", "Video", "Power", "Rigging", "Cases", "Other"
    ]

    private var isValid: Bool {
        !sku.trimmingCharacters(in: .whitespaces).isEmpty
        && !name.trimmingCharacters(in: .whitespaces).isEmpty
        && !category.trimmingCharacters(in: .whitespaces).isEmpty
        && totalStock >= 0
    }

    var body: some View {
        Form {
            identificationSection
            classificationSection
            stockSection
        }
        .navigationTitle(mode.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
            }
        }
        .onAppear(perform: populateFieldsIfEditing)
    }

    private var identificationSection: some View {
        Section("Identification") {
            LabeledContent {
                TextField("e.g. MIX-AH-SQ6", text: $sku)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
            } label: {
                Label("SKU", systemImage: "barcode")
            }

            LabeledContent {
                TextField("e.g. Allen & Heath SQ6", text: $name)
                    .multilineTextAlignment(.trailing)
            } label: {
                Label("Name", systemImage: "textformat")
            }
        }
    }

    private var classificationSection: some View {
        Section("Classification") {
            Picker(selection: $isSerialized) {
                Label("Serialized", systemImage: "number")
                    .tag(true)
                Label("Bulk", systemImage: "cube.box.fill")
                    .tag(false)
            } label: {
                Label("Item Type", systemImage: "tag")
            }

            LabeledContent {
                TextField("e.g. Mixer", text: $category)
                    .multilineTextAlignment(.trailing)
            } label: {
                Label("Category", systemImage: "folder")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestedCategories, id: \.self) { suggestion in
                        Button(suggestion) {
                            category = suggestion
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .tint(category == suggestion ? .accentColor : .secondary)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        }
    }

    private var stockSection: some View {
        Section("Stock") {
            Stepper(value: $totalStock, in: 0...999) {
                LabeledContent {
                    Text("\(totalStock)")
                        .font(.headline.monospacedDigit())
                } label: {
                    Text("Total Stock")
                }
            }
        }
    }

    private func populateFieldsIfEditing() {
        guard case .edit(let item) = mode else { return }
        sku = item.sku
        name = item.name
        isSerialized = item.isSerialized
        category = item.category
        totalStock = item.totalStock
    }

    private func save() {
        let savedItem: InventoryItem
        let actionEnum: SyncAction
        
        switch mode {
        case .add:
            let item = InventoryItem(
                sku: sku.trimmingCharacters(in: .whitespaces),
                name: name.trimmingCharacters(in: .whitespaces),
                isSerialized: isSerialized,
                category: category.trimmingCharacters(in: .whitespaces),
                totalStock: totalStock
            )
            modelContext.insert(item)
            savedItem = item
            actionEnum = .create

        case .edit(let item):
            item.sku = sku.trimmingCharacters(in: .whitespaces)
            item.name = name.trimmingCharacters(in: .whitespaces)
            item.isSerialized = isSerialized
            item.category = category.trimmingCharacters(in: .whitespaces)
            item.totalStock = totalStock
            savedItem = item
            actionEnum = .update
        }
        
        let payload: [String: Any] = [
            "id": savedItem.id.uuidString,
            "sku": savedItem.sku,
            "name": savedItem.name,
            "is_serialized": savedItem.isSerialized,
            "category": savedItem.category,
            "total_stock": savedItem.totalStock
        ]
                
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            let mutation = SyncMutation(
                entityType: "inventoryitem",
                entityId: savedItem.id,
                action: actionEnum,
                payload: data
            )
            modelContext.insert(mutation)
        }

        dismiss()
    }
}

#Preview("Add Item") {
    NavigationStack {
        ItemFormView(mode: .add)
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
