//
//  CheckNetwork.swift
//  Shot Clock Cue Score
//
//  Created by Owner on 28/03/2025.
//

import Foundation
import Network

class NetworkMonitor: ObservableObject {
    
    @Published var isConnected: Bool = false
    private let monitor = NWPathMonitor()

    init() {
        startMonitoring()
    }

    func startMonitoring() {
        
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
}
