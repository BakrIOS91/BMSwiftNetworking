import XCTest
import Combine
@testable import BMSwiftNetworking

final class PerformanceTests: BaseNetworkingTests {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - ModelTargetType Async/Await


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

    // MARK: - ModelTargetType No-Network

    func testPerformAsyncNoNetworkModel() async {
        struct OfflineTarget: ModelTargetType {
            typealias Response = MockResponse
            var baseURL: String { "https://api.example.com" }
            var requestPath: String = "/test"
            var requestMethod: HTTPMethod = .GET
            var requestType: RequestType = .REST
            var requestTask: RequestTask = .plain
            var headers: [String: String] = [:]
            var autHeaders: [String: String] = [:]
            var interceptor: NetworkInterceptor? = nil
            var sslPinningConfiguration: SSLPinningConfiguration? = nil
            var mockResponse: MockResponse { MockResponse(id: 0, name: "Mock") }
            static var isConnectedToInternet: Bool { false }
        }

        let target = OfflineTarget()
        do {
            _ = try await target.performAsync()
            XCTFail("Should have thrown noNetwork error")
        } catch let error as APIError {
            XCTAssertEqual(error, .noNetwork)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - ModelTargetType Combine

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

    // MARK: - ModelTargetType Result

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

    // MARK: - SuccessTargetType Async/Await

    func testSuccessTargetPerformAsyncSuccess() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        let target = MockSuccessTarget()
        // Should complete without throwing
        try await target.performAsync()
    }

    func testSuccessTargetPerformAsyncFailure() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        let target = MockSuccessTarget()
        do {
            try await target.performAsync()
            XCTFail("Should have thrown an error")
        } catch let error as APIError {
            XCTAssertEqual(error, .httpError(statusCode: .serverError))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSuccessTargetPerformAsyncNoNetwork() async {
        struct OfflineSuccessTarget: SuccessTargetType {
            var baseURL: String { "https://api.example.com" }
            var requestPath: String = "/success"
            var requestMethod: HTTPMethod = .POST
            var requestType: RequestType = .REST
            var requestTask: RequestTask = .plain
            var headers: [String: String] = [:]
            var autHeaders: [String: String] = [:]
            var interceptor: NetworkInterceptor? = nil
            var sslPinningConfiguration: SSLPinningConfiguration? = nil
            static var isConnectedToInternet: Bool { false }
        }

        let target = OfflineSuccessTarget()
        do {
            try await target.performAsync()
            XCTFail("Should have thrown noNetwork error")
        } catch let error as APIError {
            XCTAssertEqual(error, .noNetwork)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - SuccessTargetType Result

    func testSuccessTargetPerformResultSuccess() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        let target = MockSuccessTarget()
        let result = await target.performResult()

        if case .failure(let error) = result {
            XCTFail("Result should have been success, got error: \(error)")
        }
    }

    func testSuccessTargetPerformResultFailure() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 403, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        let target = MockSuccessTarget()
        let result = await target.performResult()

        if case .success = result {
            XCTFail("Result should have been failure")
        }
        if case .failure(let error) = result {
            XCTAssertEqual(error, .httpError(statusCode: .clientError))
        }
    }

    // MARK: - SuccessTargetType Combine

    func testSuccessTargetPerformPublisherSuccess() {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        let target = MockSuccessTarget()
        let expectation = XCTestExpectation(description: "SuccessTarget publisher completes")

        target.performPublisher()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Should not fail: \(error)")
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func testSuccessTargetPerformPublisherFailure() {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        let target = MockSuccessTarget()
        let expectation = XCTestExpectation(description: "SuccessTarget publisher fails")

        target.performPublisher()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTAssertEqual(error, .httpError(statusCode: .serverError))
                    expectation.fulfill()
                }
            }, receiveValue: { _ in
                XCTFail("Should not receive a value on failure")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }
}
