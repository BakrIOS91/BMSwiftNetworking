//
//  NetworkMonitor.swift
//
//  Created by Bakr Mohamed on 05/08/2024.
//

import Network
import Combine

public class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue.main
    
    private var status: NWPath.Status = .requiresConnection
    private var isCellular: Bool = false
    
    /// Published connectivity states for observation
    @Published public private(set) var isReachable: Bool = false
    @Published public private(set) var isReachableOnWiFi: Bool = false
    @Published public private(set) var isReachableOnCellular: Bool = false
    
    private init () {
        monitor = NWPathMonitor()
    }
    
    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            self.status = path.status
            self.isCellular = path.status == .satisfied && path.isExpensive
            
            // Update observable properties on main thread
            DispatchQueue.main.async {
                self.isReachable = self.status == .satisfied
                self.isReachableOnCellular = self.status == .satisfied && self.isCellular
                self.isReachableOnWiFi = self.status == .satisfied && !self.isCellular
            }
        }
        monitor.start(queue: queue)
    }
    
    public func stopMonitoring() {
        monitor.cancel()
    }
    
    /// Returns `true` if network is reachable via Wi-Fi **or** Cellular
    public func isNetworkReachable() -> Bool {
        return isReachableOnWiFi || isReachableOnCellular
    }
}
