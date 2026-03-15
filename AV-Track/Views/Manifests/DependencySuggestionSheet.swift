//
//  DependencySuggestionSheet.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 15.03.2026..
//

import SwiftUI
import SwiftData

struct DependencySuggestionSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let dependencies: [ItemDependency]
    let onAccept: (ItemDependency) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Recommended Accessories").font(.subheadline)) {
                    ForEach(dependencies, id: \.id) { dependency in
                        if let child = dependency.childItem {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(child.name)
                                        .font(.headline)
                                    
                                    if !dependency.note.isEmpty {
                                        Text(dependency.note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Button {
                                    onAccept(dependency)
                                } label: {
                                    Text("Add")
                                        .fontWeight(.semibold)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Smart Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
