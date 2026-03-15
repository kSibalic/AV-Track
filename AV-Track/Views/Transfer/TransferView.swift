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
    @State private var hiddenScanInput = ""
    @FocusState private var isScannerFocused: Bool
    
    @Query(sort: \JobManifest.eventDate) private var manifests: [JobManifest]
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("Scanner", text: $hiddenScanInput)
                .focused($isScannerFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit {
                    guard !hiddenScanInput.isEmpty else { return }
                    let sku = hiddenScanInput
                    hiddenScanInput = ""
                    
                    viewModel.handleScan(sku: sku, modelContext: modelContext)
                    ScannerInputManager.shared.lastScannedSKU = sku
                    
                    Task { @MainActor in
                        isScannerFocused = true
                    }
                }
            
            VStack(spacing: 16) {
                manifestPicker
                locationCards
            }
            .padding(.bottom, 16)
            .background(Color(uiColor: .systemGroupedBackground))
            
            Divider()
            
            Group {
                if viewModel.activeManifest != nil {
                    manifestChecklist
                } else if viewModel.transferHistory.isEmpty {
                    ContentUnavailableView(
                        "Ready to Transfer",
                        systemImage: "scanner",
                        description: Text("Connect your scanner and scan an item to instantly move it to \(viewModel.destinationLocation).")
                    )
                } else {
                    transferHistoryList
                }
            }
        }
        .navigationTitle("Transfer Mode")
        .onAppear { isScannerFocused = true }
        .onTapGesture { isScannerFocused = true }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showQuantityPicker) {
            if let item = viewModel.pendingBulkItem {
                let maxAvailable = item.locations.filter { $0.locationName != viewModel.destinationLocation }.reduce(0) { $0 + $1.quantity }
                
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
        .alert("Item Not In Manifest", isPresented: $viewModel.showScanAlert) {
            Button("OK", role: .cancel) {
                viewModel.scanAlertMessage = nil
            }
        } message: {
            if let msg = viewModel.scanAlertMessage {
                Text(msg)
            }
        }
    }
    
    private var manifestPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("UPCOMING MANIFEST")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            
            Menu {
                Button("No Manifest (Free Transfer)") {
                    viewModel.activeManifest = nil
                }
                Divider()
                ForEach(manifests.filter { $0.status != .returned }) { manifest in
                    Button(manifest.jobName) {
                        viewModel.activeManifest = manifest
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "list.clipboard")
                        .foregroundStyle(viewModel.activeManifest == nil ? .secondary : Color.accentColor)
                    if let manifest = viewModel.activeManifest {
                        Text(manifest.jobName)
                            .foregroundStyle(.primary)
                            .fontWeight(.medium)
                    } else {
                        Text("Select a manifest...")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private var locationCards: some View {
        HStack(spacing: 16) {
            locationCard(title: "DESTINATION", selection: $viewModel.destinationLocation)
        }
        .padding(.horizontal)
    }
    
    private func locationCard(title: String, selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            
            Menu {
                ForEach(AppLocations.all, id: \.self) { loc in
                    Button(loc) { selection.wrappedValue = loc }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
            }
        }
    }
    
    private var manifestChecklist: some View {
        List {
            Section("Packing List") {
                if let manifest = viewModel.activeManifest {
                    let sortedItems = manifest.items.sorted {
                        ($0.item?.name ?? "") < ($1.item?.name ?? "")
                    }
                    
                    ForEach(sortedItems) { manifestItem in
                        let packed = manifestItem.packedQuantity
                        let required = manifestItem.quantity
                        let remaining = max(0, required - packed)
                        let isDone = remaining == 0
                        
                        HStack {
                            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isDone ? .green : .gray)
                                .font(.title3)
                            
                            if let item = manifestItem.item {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .strikethrough(isDone)
                                        .foregroundStyle(isDone ? .secondary : .primary)
                                        .font(.headline)
                                    Text(item.sku)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if isDone {
                                Text("Packed")
                                    .font(.caption.bold())
                                    .foregroundStyle(.green)
                            } else {
                                VStack(alignment: .trailing) {
                                    Text("\(remaining) left")
                                        .font(.subheadline.bold())
                                    Text("of \(required)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .opacity(isDone ? 0.6 : 1.0)
                        .animation(.spring(), value: packed)
                    }
                }
            }
            
            Section("Recent Transfer History") {
                ForEach(viewModel.transferHistory.prefix(3)) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.item.name)
                                .font(.subheadline)
                            Text(record.message)
                                .font(.caption2)
                                .foregroundStyle(record.success ? .green : .red)
                        }
                        Spacer()
                        Text("x\(record.quantity)")
                            .font(.subheadline.monospacedDigit())
                    }
                }
            }
        }
        .listStyle(.grouped)
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
