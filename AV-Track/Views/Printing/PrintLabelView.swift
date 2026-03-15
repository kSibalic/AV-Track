//
//  PrintLabelView.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 15.03.2026..
//

import Foundation
import SwiftUI

struct PrintLabelView: View {
    @Environment(\.dismiss) private var dismiss
    let item: InventoryItem
    
    @AppStorage("printerIPAddress") private var printerIP = ""
    @State private var printerService = PrinterService.shared
    
    @State private var labelImage: UIImage?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Label Preview") {
                    VStack {
                        if let image = labelImage {
                            Image(uiImage: image)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 2)
                        } else {
                            ProgressView()
                                .frame(height: 140)
                        }
                        
                        Text(item.sku)
                            .font(.headline.monospaced())
                            .padding(.top, 8)
                        
                        Text(item.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                
                Section("Printer Connection") {
                    LabeledContent("Target Printer", value: "PT-E550W")
                    
                    TextField("Printer IP Address", text: $printerIP)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                    
                    if let error = printerService.printError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Print Label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await submitPrintJob()
                        }
                    } label: {
                        if printerService.isPrinting {
                            ProgressView()
                        } else {
                            Text("Print")
                                .fontWeight(.bold)
                        }
                    }
                    .disabled(printerIP.isEmpty || labelImage == nil || printerService.isPrinting)
                }
            }
            .onAppear {
                generatePreview()
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func generatePreview() {
        let skuToGenerate = item.sku
        
        Task { @MainActor in
            let image = BarcodeGenerator.generate(from: skuToGenerate)
            self.labelImage = image ?? UIImage(systemName: "exclamationmark.triangle.fill")
        }
    }
    
    private func submitPrintJob() async {
        guard let image = labelImage else { return }
        await printerService.printLabel(image: image, ipAddress: printerIP)
        if printerService.printError == nil {
            dismiss()
        }
    }
}
