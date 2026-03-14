//
//  TransferView.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 14.03.2026..
//

import SwiftUI
import SwiftData

struct TransferView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TransferViewModel()
    @State private var scanner = ScannerInputManager.shared
    
    let locations = ["Warehouse", "Truck", "Van", "Client Site", "House", "Office"]
    
    var body: some View {
        Group {
            if viewModel.transferHistory.isEmpty {
                ContentUnavailableView(
                    "Ready to Transfer",
                    systemImage: "scanner",
                    description: Text("Connect your scanner and scan an item to instantly move it from \(viewModel.sourceLocation) to \(viewModel.destinationLocation).")
                )
            } else {
                transferHistoryList
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                locationHeader
                Divider()
            }
            .background(.bar)
        }
        .navigationTitle("Transfer Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scanner.lastScannedSKU) { _, newSKU in
            guard let sku = newSKU else { return }
            viewModel.handleScan(sku: sku, modelContext: modelContext)
            scanner.lastScannedSKU = nil
        }
        .sheet(isPresented: $viewModel.showQuantityPicker) {
            if let item = viewModel.pendingBulkItem {
                let maxAvailable = item.locations.first(where: { $0.locationName == viewModel.sourceLocation })?.quantity ?? 0
                
                BulkQuantityPicker(
                    item: item,
                    maxQuantity: maxAvailable,
                    onConfirm: { quantity in
                        viewModel.performTransfer(item: item, quantity: quantity, modelContext: modelContext)
                        viewModel.showQuantityPicker = false
                        viewModel.pendingBulkItem = nil
                    },
                    onCancel: {
                        viewModel.showQuantityPicker = false
                        viewModel.pendingBulkItem = nil
                    }
                )
            }
        }
    }
    
    private var locationHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("FROM")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("Source", selection: $viewModel.sourceLocation) {
                        ForEach(locations, id: \.self) { loc in
                            Text(loc).tag(loc)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(8)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 16)
                
                VStack(alignment: .leading) {
                    Text("TO")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("Destination", selection: $viewModel.destinationLocation) {
                        ForEach(locations, id: \.self) { loc in
                            Text(loc).tag(loc)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(8)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal)
            
            if viewModel.sourceLocation == viewModel.destinationLocation {
                Label("Source and Destination are the same.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical)
    }
    
    private var transferHistoryList: some View {
        List {
            Section("Recent Transfers") {
                ForEach(viewModel.transferHistory) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.item.name)
                                .font(.headline)
                            Text(record.message)
                                .font(.caption)
                                .foregroundStyle(record.success ? .green : .red)
                        }
                        
                        Spacer()
                        
                        Text("x\(record.quantity)")
                            .font(.title3.monospacedDigit())
                            .fontWeight(.medium)
                            .foregroundStyle(record.success ? .primary : .secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    NavigationStack {
        TransferView()
    }
    .modelContainer(for: [InventoryItem.self, ItemLocation.self, ItemDependency.self, SyncMutation.self, JobManifest.self, ManifestItem.self], inMemory: true)
}
