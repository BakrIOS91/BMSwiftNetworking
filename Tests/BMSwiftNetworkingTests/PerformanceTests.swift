import XCTest
import Combine
@testable import BMSwiftNetworking

final class PerformanceTests: BaseNetworkingTests {
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Async/Await Tests
    
    func testPerformAsyncSuccess() async throws {
        let expectedResponse = MockResponse(id: 1, name: "Test")
        let responseData = try JSONEncoder().encode(expectedResponse)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }
        
        let target = MockTarget()
        let result = try await target.performAsync()
        
        XCTAssertEqual(result, expectedResponse)
    }
    
    func testPerformAsyncFailure404() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        let target = MockTarget()
        
        do {
            _ = try await target.performAsync()
            XCTFail("Should have thrown an error")
        } catch let error as APIError {
            XCTAssertEqual(error, .httpError(statusCode: .notFound))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testPerformAsyncDecodingFailure() async throws {
        let invalidData = "invalid json".data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, invalidData)
        }
        
        let target = MockTarget()
        
        do {
            _ = try await target.performAsync()
            XCTFail("Should have thrown a decoding error")
        } catch let error as APIError {
            XCTAssertEqual(error, .dataConversionFailed)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Combine Tests
    
    func testPerformPublisherSuccess() {
        let expectedResponse = MockResponse(id: 1, name: "Test")
        let responseData = try! JSONEncoder().encode(expectedResponse)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }
        
        let target = MockTarget()
        let expectation = XCTestExpectation(description: "Publisher receives response")
        
        target.performPublisher()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Publisher failed with error: \(error)")
                }
            }, receiveValue: { response in
                XCTAssertEqual(response, expectedResponse)
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testPerformPublisherFailure() {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        let target = MockTarget()
        let expectation = XCTestExpectation(description: "Publisher receives error")
        
        target.performPublisher()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTAssertEqual(error, .httpError(statusCode: .serverError))
                    expectation.fulfill()
                }
            }, receiveValue: { _ in
                XCTFail("Publisher should not have received a value")
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Result Tests
    
    func testPerformResultSuccess() async {
        let expectedResponse = MockResponse(id: 1, name: "Test")
        let responseData = try! JSONEncoder().encode(expectedResponse)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }
        
        let target = MockTarget()
        let result = await target.performResult()
        
        switch result {
        case .success(let response):
            XCTAssertEqual(response, expectedResponse)
        case .failure(let error):
            XCTFail("Result was failure: \(error)")
        }
    }
    
    func testPerformResultFailure() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        let target = MockTarget()
        let result = await target.performResult()
        
        switch result {
        case .success:
            XCTFail("Result should have been failure")
        case .failure(let error):
            XCTAssertEqual(error, .httpError(statusCode: .notAuthorize))
        }
    }
}
