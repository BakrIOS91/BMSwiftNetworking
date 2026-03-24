import XCTest
import Combine
@testable import BMSwiftNetworking

final class RecurringRequestTests: BaseNetworkingTests {
    private var cancellables = Set<AnyCancellable>()
    
    func testPerformAsyncStreamSuccess() async throws {
        let expectedResponse = MockResponse(id: 1, name: "Test")
        let responseData = try! JSONEncoder().encode(expectedResponse)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }
        
        let target = MockTarget()
        // Use a very small interval for testing
        let stream = target.performAsyncStream(repeatingEveryMinutes: 0.001)
        
        var receivedCount = 0
        let maxCount = 3
        
        for try await response in stream {
            XCTAssertEqual(response, expectedResponse)
            receivedCount += 1
            if receivedCount >= maxCount {
                break
            }
        }
        
        XCTAssertEqual(receivedCount, maxCount)
    }
    
    func testPerformPublisherRecurringSuccess() {
        let expectedResponse = MockResponse(id: 1, name: "Test")
        let responseData = try! JSONEncoder().encode(expectedResponse)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }
        
        let target = MockTarget()
        let expectation = XCTestExpectation(description: "Publisher receives multiple responses")
        expectation.expectedFulfillmentCount = 3
        
        target.performPublisher(repeatingEveryMinutes: 0.001)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Publisher failed with error: \(error)")
                }
            }, receiveValue: { response in
                XCTAssertEqual(response, expectedResponse)
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testPerformResultStreamSuccess() async {
        let expectedResponse = MockResponse(id: 1, name: "Test")
        let responseData = try! JSONEncoder().encode(expectedResponse)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }
        
        let target = MockTarget()
        let stream = target.performResultStream(repeatingEveryMinutes: 0.001)
        
        var receivedCount = 0
        let maxCount = 3
        
        for await result in stream {
            if case .success(let response) = result {
                XCTAssertEqual(response, expectedResponse)
                receivedCount += 1
            } else {
                XCTFail("Result should have been success")
            }
            
            if receivedCount >= maxCount {
                break
            }
        }
        
        XCTAssertEqual(receivedCount, maxCount)
    }
}
