import Foundation

/// A custom URLProtocol that allows us to mock network responses.
final class MockURLProtocol: URLProtocol {
    /// A closure that handles a URLRequest and returns a mocked response and data, or an error.
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool {
        // Handle all requests
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is not set.")
        }

        do {
            // Call the handler to get the mocked response and data
            let (response, data) = try handler(request)

            // Notify the client about the response
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

            if let data = data {
                // Notify the client about the data
                client?.urlProtocol(self, didLoad: data)
            }

            // Notify the client that loading has finished
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            // Notify the client about the error
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // This method is required but doesn't need implementation for mocks
    }
}
