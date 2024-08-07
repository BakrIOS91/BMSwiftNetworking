//
//  TargetRequest.swift
//
//
//  Created by Bakr mohamed on 12/01/2024.
//

import Foundation

/// Protocol defining the properties required for a target network request.
///
/// A `TargetRequest` specifies the essential components of a network request,
/// including the base URL, request path, HTTP method, request task, and headers.
///
/// - `requestType`: Request Type that Present if the Request REST or SOAP
/// - `baseURL`: The base URL for the network request.
/// - `requestPath`: The specific path to be appended to the base URL for the request.
/// - `requestMethod`: The HTTP method to be used for the request (e.g., GET, POST, PUT).
/// - `requestTask`: The type of task to be performed as part of the network request (e.g., plain request, download, upload).
/// - `headers`: The headers to be included in the request.
public protocol TargetRequest {
    /// Request Type that Present if the Request REST or SOAP
    var requestType: RequestType { get }
    
    /// The base URL for the network request.
    var baseURL: String { get }
    
    /// The specific path to be appended to the base URL for the request.
    var requestPath: String { get }
    
    /// The HTTP method to be used for the request (e.g., GET, POST, PUT).
    var requestMethod: HTTPMethod { get }
    
    /// The type of task to be performed as part of the network request (e.g., plain request, download, upload).
    var requestTask: RequestTask { get }
    
    /// The headers to be included in the request.
    var headers: [String: String] { get }
    
    /// The headers to be included in the request.
    var autHeaders: [String: String] { get }
    
    /// SLLPining
    var sslCertificates: [SecCertificate] { get }
}

/// Default implementation of `TargetRequest` protocol, providing a plain request task by default.
/// This extension allows conforming types to use a default implementation for the `requestTask` property.
/// Conforming types can override this property to customize the task if needed.
public extension TargetRequest {
    /// Default Request type to REST
    var requestType: RequestType { return .REST }
    
    /// Default headers to be Empty
    var headers: [String: String] {
        return [:]
    }
    /// Default authHeader
    var autHeaders: [String: String] {
        return [:]
    }
    
    /// Default headers for the request.
    var defaultHeaders: [String: String] {
        var headers: [String: String] = [:]
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        return headers
    }
    
    var requestTask: RequestTask {
        return .plain
    }
    
    /// Merges the default headers with the provided headers.
    /// If a header with the same key exists in both, the provided header takes precedence.
    /// - Returns: Merged headers.
    var mergedHeaders: [String: String] {
        var combinedHeaders = headers.merging(autHeaders) { (_, new) in new }
        return defaultHeaders.merging(combinedHeaders) { (_, new) in new }
    }
    
    /// Default Sec Certificates
    var sslCertificates: [SecCertificate] { return [] }
    
    /// Use this to check about internet connection
    static var isConnectedToInternet: Bool {
        return NetworkMonitor.shared.isReachable
    }
}

/// Protocol for a successful network request.
/// `SuccessTargetType` is a marker protocol indicating that a network request is expected to be successful.
/// Conforming to this protocol allows for a clear distinction between successful and unsuccessful requests.
public protocol SuccessTargetType: TargetRequest { }

/// Protocol for a network request that expects a Codable response model.
/// `ModelTargetType` is a specialized protocol for network requests that are expected to
/// receive a response in the form of a Codable model conforming to the associated `Response` type.
public protocol ModelTargetType: TargetRequest {
    /// The Codable response type expected from the network request.
    associatedtype Response: Codable
    var mockResponse: Response  { get }
}
