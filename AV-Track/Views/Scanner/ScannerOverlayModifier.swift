//
//  ScannerOverlayModifier.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 14.03.2026..
//

import SwiftUI

struct ScannerOverlayModifier: ViewModifier {
    @State private var scanner = ScannerInputManager.shared
    @FocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
                .focusable()
                .focused($isFocused)
                .focusEffectDisabled()
                .onKeyPress(phases: .down) { press in
                    scanner.handleKeyPress(press)
                }
                .onAppear {
                    isFocused = true
                }
            
            if let sku = scanner.lastScannedSKU {
                HStack(spacing: 12) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.title2)
                        .foregroundStyle(.white)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scanned")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Text(sku)
                            .font(.headline.monospaced())
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.gray.opacity(0.8))
                .background(Material.ultraThin)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                .padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: scanner.lastScannedSKU)
    }
}

extension View {
    func scannerEnvironment() -> some View {
        self.modifier(ScannerOverlayModifier())
    }
}

#Preview {
    Color.white
        .scannerEnvironment()
        .onAppear {
            ScannerInputManager.shared.lastScannedSKU = "MIX-AH-SQ6"
        }
}
