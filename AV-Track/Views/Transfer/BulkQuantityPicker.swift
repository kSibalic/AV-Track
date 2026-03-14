//
//  BulkQuantityPicker.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 14.03.2026..
//

import SwiftUI

struct BulkQuantityPicker: View {
    let item: InventoryItem
    let maxQuantity: Int
    let onConfirm: (Int) -> Void
    let onCancel: () -> Void
    
    @State private var inputStack: String = ""
    
    var currentQuantity: Int {
        Int(inputStack) ?? 0
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Transfer Quantity")
                .font(.headline)
            
            Text(item.name)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("\(currentQuantity)")
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    Text("Max: \(maxQuantity)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(),
                    alignment: .bottomTrailing
                )
            
            let columns = Array(repeating: GridItem(.flexible()), count: 3)
            LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(1...9, id: \.self) { num in
                                Button(action: { append(num) }) {
                                    NumpadKey(title: "\(num)")
                                }
                            }
                
                Button(action: clear) {
                    NumpadKey(title: "CLR", color: .red.opacity(0.8))
                }
                
                Button(action: { append(0) }) {
                    NumpadKey(title: "0")
                }
                
                Button(action: delete) {
                    NumpadKey(icon: "delete.left")
                }
            }
            .padding(.vertical)
            
            HStack(spacing: 16) {
                Button("Cancel", role: .cancel, action: onCancel)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                
                Button("Confirm Transfer") {
                    onConfirm(currentQuantity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(currentQuantity <= 0 || currentQuantity > maxQuantity)
            }
        }
        .padding()
        .presentationDetents([.fraction(0.65), .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
    }
    
    private func append(_ num: Int) {
        if inputStack.count < 6 {
            inputStack.append("\(num)")
        }
    }
    
    private func delete() {
        if !inputStack.isEmpty {
            inputStack.removeLast()
        }
    }
    
    private func clear() {
        inputStack = ""
    }
}

private struct NumpadKey: View {
    var title: String? = nil
    var icon: String? = nil
    var color: Color = Color(.tertiarySystemFill)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .frame(height: 70)
            
            if let title {
                Text(title)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            } else if let icon {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(.primary)
            }
        }
    }
}
