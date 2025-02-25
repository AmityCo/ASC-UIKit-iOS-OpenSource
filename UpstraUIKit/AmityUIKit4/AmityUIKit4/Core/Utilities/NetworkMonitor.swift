//
//  NetworkMonitor.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 3/4/2567 BE.
//

import Foundation
import Network

class NetworkMonitor: ObservableObject {
    
    static let shared = NetworkMonitor()
    
    private let networkMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue(label: "Monitor")
    
    @Published var isConnected = false

    init() {
        networkMonitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: workerQueue)
    }
}
