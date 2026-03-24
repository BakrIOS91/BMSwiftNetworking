import XCTest
@testable import BMSwiftNetworking

final class RequestFormattingTests: BaseNetworkingTests {
    
    func testPlainRequest() throws {
        var target = MockTarget()
        target.requestTask = .plain
        
        let request = try target.createRequest()
        
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/test")
        XCTAssertEqual(request.httpMethod, "GET")
    }
    
    func testRequestWithParameters() throws {
        var target = MockTarget()
        target.requestTask = .parameters(["key1": "value1", "key2": 123])
        
        let request = try target.createRequest()
        
        let urlString = request.url?.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("key1=value1"))
        XCTAssertTrue(urlString.contains("key2=123"))
    }
    
    func testRequestWithJSONBody() throws {
        let body = MockResponse(id: 1, name: "Test")
        var target = MockTarget()
        target.requestMethod = .POST
        target.requestTask = .encodedBody(body)
        
        let request = try target.createRequest()
        
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        
        guard let httpBody = request.httpBody else {
            XCTFail("HTTP body should not be nil")
            return
        }
        
        let decodedBody = try JSONDecoder().decode(MockResponse.self, from: httpBody)
        XCTAssertEqual(decodedBody, body)
    }
    
    func testRequestWithHeaders() throws {
        var target = MockTarget()
        target.headers = ["Authorization": "Bearer token123", "Custom-Header": "CustomValue"]
        
        let request = try target.createRequest()
        
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token123")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Custom-Header"), "CustomValue")
    }
    
    func testMultipartRequest() throws {
        let data = "Hello World".data(using: .utf8)!
        var target = MockTarget()
        target.requestMethod = .POST
        target.requestTask = .uploadMultipart([
            "file": .data(data, fileName: "test.txt", mimeType: "text/plain"),
            "text": .text("Some text")
        ])
        
        let request = try target.createRequest()
        
        let contentType = request.value(forHTTPHeaderField: "Content-Type") ?? ""
        XCTAssertTrue(contentType.contains("multipart/form-data"))
        XCTAssertTrue(contentType.contains("boundary="))
        
        guard let body = request.httpBody else {
            XCTFail("Body should not be nil")
            return
        }
        
        let bodyString = String(data: body, encoding: .utf8) ?? ""
        XCTAssertTrue(bodyString.contains("Content-Disposition: form-data; name=\"file\"; filename=\"test.txt\""))
        XCTAssertTrue(bodyString.contains("Content-Type: text/plain"))
        XCTAssertTrue(bodyString.contains("Hello World"))
        XCTAssertTrue(bodyString.contains("Content-Disposition: form-data; name=\"text\""))
        XCTAssertTrue(bodyString.contains("Some text"))
    }
}
