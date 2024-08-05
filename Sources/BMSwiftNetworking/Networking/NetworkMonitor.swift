//
//  NetworkMonitor.swift
//
//
//  Created by Bakr mohamed on 05/08/2024.
//

import Network

public class NetworkMonitor {
    public static let shared = NetworkMonitor()
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private var status: NWPath.Status = .requiresConnection
    var isReachable: Bool { status == .satisfied }
    var isReachableOnCellular: Bool = true
    
    private init () {
        monitor = NWPathMonitor()
    }
    
    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.status = path.status
            self?.isReachableOnCellular = path.isExpensive
        }
        monitor.start(queue: queue)
    }
    
    
    
    public func stopMonitoring() {
        monitor.cancel()
    }
}
