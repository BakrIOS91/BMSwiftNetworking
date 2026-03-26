//
//  NetworkMonitor.swift
//
//  Created by Bakr Mohamed on 05/08/2024.
//

import Network
import SwiftUI

public class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published public private(set) var isConnected: Bool = true
    @Published public private(set) var connectionType: ConnectionType = .unknown
    
    public enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    public init() {
        startMonitoring()
    }
    
    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                #if DEBUG
                // In Previews or Tests, we often want to assume connectivity 
                // especially if we are using MockURLProtocol.
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ||
                    NSClassFromString("XCTestCase") != nil {
                    self.isConnected = true
                    return
                }
                #endif
                
                self.isConnected = path.status == .satisfied
                self.updateConnectionType(path)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    public func stopMonitoring() {
        monitor.cancel()
    }
    
    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
    
    /// Checks the current network status
    /// - Returns: Boolean indicating whether the device is connected to the network
    public func checkNetworkStatus() -> Bool {
        return isConnected
    }
    
    deinit {
        stopMonitoring()
    }
}
