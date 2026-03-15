//
//  NetworkMonitor.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 15.03.2026..
//

import SwiftUI
import Network

@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    var isConnected = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "AVTrack.NetworkMonitor")
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
