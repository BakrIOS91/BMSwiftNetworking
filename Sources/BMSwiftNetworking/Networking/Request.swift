//
//  Request.swift
//
//
//  Created by Bakr mohamed on 15/01/2024.
//

import Foundation

extension TargetRequest {
    /// Creates a `URLRequest` based on the specified `TargetRequest` and the current `Task`.
    /// - Parameters:
    ///   - target: The target request containing information like base URL, path, method, headers, etc.
    /// - Returns: A configured `URLRequest` for the specified task.
    /// - Throws: An `APIError` if there is an error in URL formation, data conversion, or JSON encoding.
    func createRequest() throws -> URLRequest  {
        guard let url = URL(string: baseURL + requestPath) else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = requestMethod.rawValue
        urlRequest.allHTTPHeaderFields = mergedHeaders
        
        switch requestType {
            case .REST:
                // Configuration for REST requests
                try configureRESTRequest(&urlRequest)
            case .SOAP:
                // Configuration for SOAP requests
                try configureSOAPRequest(&urlRequest)
        }
        
        requestLogger(request: urlRequest)
        
        return urlRequest
    }
    
    /// Configures a `URLRequest` for a REST request based on the specified `Task`.
    /// - Parameter urlRequest: The `URLRequest` to be configured.
    /// - Throws: An `APIError` if there is an error in URL encoding, data conversion, or JSON encoding.
    func configureRESTRequest(_ urlRequest: inout URLRequest) throws {
        switch requestTask {
            case .plain, .download:
                // No additional configuration needed for plain request.
                break
                
            case .parameters(let parameters):
                // Add URL-encoded parameters to the request URL.
                if let url = urlRequest.url,
                   var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
                    urlRequest.url = components.url
                }
                
            case .encodedBody(let encodable):
            // Set the request body as JSON from an Encodable type
               let encoder = JSONEncoder()
               do {
                   // Encode the encodable object to JSON
                   let requestBody = try encoder.encode(encodable)
                   
                   // Set the request body
                   urlRequest.httpBody = requestBody
                   
                   // Set the Content-Length header (in bytes)
                   let contentLength = String(requestBody.count)
                   urlRequest.setValue(contentLength, forHTTPHeaderField: "Content-Length")
                   
                   // Set the Content-Type header to indicate the request body is JSON
                   urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
               } catch {
                   // Handle encoding failure
                   throw APIError.dataConversionFailed
               }
                
            case .uploadFile(let uRL):
                // Create a file upload request.
                urlRequest.httpBody = try? Data(contentsOf: uRL)
                
            case .uploadMultipart(let dictionary):
                // Create a multipart form data request.
                let boundary = "Boundary-\(UUID().uuidString)"
                urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                urlRequest.httpBody = try createMultipartBody(with: dictionary, boundary: boundary)
                
        case .downloadResumable(let data, let int64):
                // Configure resumable download with optional existing data and offset.
                urlRequest.httpBody = data
                if let offset = int64 {
                    urlRequest.addValue("bytes=\(offset)-", forHTTPHeaderField: "Range")
                }
        }
    }
    
    /// Configures a `URLRequest` for a SOAP request based on the specified `Task`.
    /// - Parameter urlRequest: The `URLRequest` to be configured.
    /// - Throws: An `APIError` if there is an error in URL encoding, data conversion, or XML encoding.
    private func configureSOAPRequest(_ urlRequest: inout URLRequest) throws {
        throw APIError.notSupportedSOAPOperation
    }
    
    /// Creates a multipart form data body for a given dictionary and boundary.
    /// - Parameters:
    ///   - data: The dictionary containing multipart form data.
    ///   - boundary: The boundary string for separating different parts of the form data.
    /// - Returns: The multipart form data body as `Data`.
    /// - Throws: An `APIError` if there is an error in string conversion.
    private func createMultipartBody(with data: [String: MultipartFormData], boundary: String) throws -> Data {
        var body = Data()
        
        for (key, value) in data {
            // Ensure the boundary and end line data can be converted to Data
            guard let boundaryData = "--\(boundary)\r\n".data(using: .utf8),
                  let endLineData = "\r\n".data(using: .utf8) else {
                throw APIError.stringConversionFailed
            }
            
            // Append the boundary data
            body.append(boundaryData)
            
            switch value {
            case .data(let data, let fileName, let mimeType):
                // Ensure content disposition and content type data can be converted to Data
                guard let contentDispositionData = "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8),
                      let contentTypeData = "Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8) else {
                    throw APIError.stringConversionFailed
                }
                
                // Append content disposition, content type, file data, and end line data
                body.append(contentDispositionData)
                body.append(contentTypeData)
                body.append(data)
                body.append(endLineData)
                
            case .text(let text):
                // Ensure text data and content disposition data can be converted to Data
                guard let textData = "\(text)\r\n".data(using: .utf8),
                      let contentDispositionData = "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8) else {
                    throw APIError.stringConversionFailed
                }
                
                // Append content disposition, text data, and end line data
                body.append(contentDispositionData)
                body.append(textData)
                body.append(endLineData)
            }
        }
        
        // Ensure the boundary end data can be converted to Data
        guard let boundaryEndData = "--\(boundary)--\r\n".data(using: .utf8) else {
            throw APIError.stringConversionFailed
        }
        
        // Append the boundary end data
        body.append(boundaryEndData)
        
        return body
    }
}
