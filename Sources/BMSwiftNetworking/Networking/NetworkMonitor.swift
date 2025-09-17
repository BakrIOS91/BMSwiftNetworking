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
    private var isCellular: Bool = false
    
    public var isReachable: Bool {
        status == .satisfied
    }
    
    public var isReachableOnCellular: Bool {
        isReachable && isCellular
    }
    
    private init () {
        monitor = NWPathMonitor()
    }
    
    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            self.status = path.status
            self.isCellular = path.status == .satisfied && path.isExpensive
        }
        monitor.start(queue: queue)
    }
    
    public func stopMonitoring() {
        monitor.cancel()
    }
    
    /// Returns `true` if network is reachable via Wi-Fi **or** Cellular
    public func isNetworkReachable() -> Bool {
        return isReachable || isReachableOnCellular
    }
}

