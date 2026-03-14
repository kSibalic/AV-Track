//
//  ScannerInputManager.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 14.03.2026..
//

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
final class ScannerInputManager {
    static let shared = ScannerInputManager()
    
    var lastScannedSKU: String? {
        didSet {
            if lastScannedSKU != nil {
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    self.lastScannedSKU = nil
                }
            }
        }
    }
    
    private var buffer = ""
    private var lastKeystrokeTime: Date = .distantPast
    
    private init() {}
    
    func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        let now = Date()
        
        if now.timeIntervalSince(lastKeystrokeTime) > 0.1 && !buffer.isEmpty {
            buffer = ""
        }
        
        lastKeystrokeTime = now
        
        if press.key == .return {
            if !buffer.isEmpty {
                lastScannedSKU = buffer
                buffer = ""
                return .handled
            }
            
            return .ignored
        }
        
        if press.characters.count == 1 {
            buffer.append(press.characters)
            return .handled
        }
        
        return .ignored
    }
}
