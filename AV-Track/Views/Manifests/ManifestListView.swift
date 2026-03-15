//
//  ManifestListView.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 15.03.2026..
//

import SwiftUI
import SwiftData

struct ManifestListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JobManifest.eventDate) private var manifests: [JobManifest]
    @State private var viewModel = ManifestViewModel()

    var body: some View {
        List {
            ForEach(manifests) { manifest in
                NavigationLink(value: manifest) {
                    ManifestRowView(manifest: manifest)
                }
            }
            .onDelete(perform: deleteManifests)
        }
        .navigationTitle("Job Manifests")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showAddManifestForm = true
                } label: {
                    Label("New Job", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddManifestForm) {
            NavigationStack {
                Form {
                    Section("Job Details") {
                        TextField("Job Name / Client", text: $viewModel.newManifestName)
                        DatePicker("Event Date", selection: $viewModel.newManifestDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                .navigationTitle("New Job Manifest")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { viewModel.showAddManifestForm = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") {
                            viewModel.createManifest(modelContext: modelContext)
                        }
                        .disabled(viewModel.newManifestName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .navigationDestination(for: JobManifest.self) { manifest in
            ManifestDetailView(manifest: manifest, viewModel: viewModel)
        }
    }

    private func deleteManifests(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteManifest(manifests[index], modelContext: modelContext)
        }
    }
}

struct ManifestRowView: View {
    let manifest: JobManifest

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(manifest.jobName)
                    .font(.headline)
                
                Spacer()
                
                statusBadge
            }

            HStack {
                Label(manifest.eventDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(manifest.items.count) items")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        let status = manifest.status
        Text(status.rawValue.capitalized)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.12))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch manifest.status {
        case .draft: return .orange
        case .packed: return .blue
        case .returned: return .green
        }
    }
}

#Preview {
    NavigationStack {
        ManifestListView()
    }
    .modelContainer(for: [JobManifest.self, ManifestItem.self, InventoryItem.self, ItemLocation.self, ItemDependency.self, SyncMutation.self], inMemory: true)
}
