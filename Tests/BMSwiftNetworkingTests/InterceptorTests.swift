import XCTest
@testable import BMSwiftNetworking

final class InterceptorTests: BaseNetworkingTests {
    
    class MockInterceptor: NetworkInterceptor {
        var requestIntercepted: URLRequest?
        var responseIntercepted: (request: URLRequest, responseData: Data?, response: HTTPURLResponse?, error: Error?)?
        
        let requestExpectation = XCTestExpectation(description: "Request intercepted")
        let responseExpectation = XCTestExpectation(description: "Response intercepted")
        
        func requestIntercept(_ request: URLRequest) {
            requestIntercepted = request
            requestExpectation.fulfill()
        }
        
        func responseIntercept(request: URLRequest, responseData: Data?, response: HTTPURLResponse?, error: Error?) {
            responseIntercepted = (request, responseData, response, error)
            responseExpectation.fulfill()
        }
    }
    
    func testInterceptorCallOnSuccess() async throws {
        let expectedResponse = MockResponse(id: 1, name: "Test")
        let responseData = try! JSONEncoder().encode(expectedResponse)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }
        
        let interceptor = MockInterceptor()
        var target = MockTarget()
        target.interceptor = interceptor
        
        _ = try await target.performAsync()
        
        await fulfillment(of: [interceptor.requestExpectation, interceptor.responseExpectation], timeout: 2.0)
        
        XCTAssertNotNil(interceptor.requestIntercepted)
        XCTAssertEqual(interceptor.requestIntercepted?.url?.absoluteString, "https://api.example.com/test")
        
        XCTAssertNotNil(interceptor.responseIntercepted)
        XCTAssertEqual(interceptor.responseIntercepted?.response?.statusCode, 200)
        XCTAssertEqual(interceptor.responseIntercepted?.responseData, responseData)
        XCTAssertNil(interceptor.responseIntercepted?.error)
    }
    
    func testInterceptorCallOnFailure() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        let interceptor = MockInterceptor()
        var target = MockTarget()
        target.interceptor = interceptor
        
        do {
            _ = try await target.performAsync()
        } catch {
            // expected error
        }
        
        await fulfillment(of: [interceptor.requestExpectation, interceptor.responseExpectation], timeout: 2.0)
        
        XCTAssertNotNil(interceptor.requestIntercepted)
        XCTAssertNotNil(interceptor.responseIntercepted)
        XCTAssertEqual(interceptor.responseIntercepted?.response?.statusCode, 500)
        XCTAssertNil(interceptor.responseIntercepted?.responseData)
        // Note: error might be APIError.httpError or something else depending on implementation
        XCTAssertNotNil(interceptor.responseIntercepted?.error)
    }
}
