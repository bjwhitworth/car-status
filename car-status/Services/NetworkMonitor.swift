//
//  NetworkMonitor.swift
//  car-status
//
//  Created by GitHub Copilot on 13/07/2025.
//

import Foundation
import Network

final class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true // Start optimistically
    @Published var connectionType: NWInterface.InterfaceType?
    private var hasInitialized = false
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
                self?.hasInitialized = true
            }
        }
        monitor.start(queue: queue)
        
        // Give a brief moment for initial network check
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if !(self?.hasInitialized ?? false) == true {
                // If still not initialized, assume we have connection
                self?.isConnected = true
                self?.hasInitialized = true
            }
        }
    }
    
    var isConnectedOrUnknown: Bool {
        return !hasInitialized || isConnected
    }
    
    var isReliablyConnected: Bool {
        return hasInitialized && isConnected
    }
    
    deinit {
        monitor.cancel()
    }
}
