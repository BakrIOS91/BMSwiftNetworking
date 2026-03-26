import XCTest
@testable import BMSwiftNetworking

final class NetworkMonitorTests: XCTestCase {
    func testNetworkMonitorInitialState() {
        let monitor = NetworkMonitor()
        XCTAssertTrue(monitor.isConnected, "NetworkMonitor should default to connected to avoid race conditions")
    }
    
    func testNetworkMonitorEnvironmentCheck() {
        let monitor = NetworkMonitor.shared
        XCTAssertTrue(monitor.isConnected, "NetworkMonitor.shared should be connected in test environment")
    }
}
