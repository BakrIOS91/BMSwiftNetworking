import XCTest
@testable import BMSwiftNetworking

class BaseNetworkingTests: XCTestCase {
    var urlSession: URLSession!

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }
    
    // Helper mock target for testing
    struct MockTarget: ModelTargetType {
        typealias Response = MockResponse
        
        var appEnvironment: AppEnvironment = .development
        var kAppHost: String = "api.example.com"
        var kAppScheme: String = "https"
        var baseURL: String { "https://api.example.com" }
        var requestPath: String = "/test"
        var requestMethod: HTTPMethod = .GET
        var requestType: RequestType = .REST
        var requestTask: RequestTask = .plain
        var headers: [String : String] = [:]
        var autHeaders: [String : String] = [:]
        var interceptor: NetworkInterceptor? = nil
        var sslPinningConfiguration: SSLPinningConfiguration? = nil
        var mockResponse: MockResponse { MockResponse(id: 0, name: "Mock") }
        
        static var isConnectedToInternet: Bool { true }
    }
    
    struct MockSuccessTarget: SuccessTargetType {
        var appEnvironment: AppEnvironment = .development
        var kAppHost: String = "api.example.com"
        var kAppScheme: String = "https"
        var baseURL: String { "https://api.example.com" }
        var requestPath: String = "/success"
        var requestMethod: HTTPMethod = .POST
        var requestType: RequestType = .REST
        var requestTask: RequestTask = .plain
        var headers: [String : String] = [:]
        var autHeaders: [String : String] = [:]
        var interceptor: NetworkInterceptor? = nil
        var sslPinningConfiguration: SSLPinningConfiguration? = nil
        
        static var isConnectedToInternet: Bool { true }
    }

    struct MockResponse: Codable, Equatable {
        let id: Int
        let name: String
    }
}
