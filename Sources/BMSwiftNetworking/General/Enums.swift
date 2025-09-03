//
//  NetworkEnums.swift
//
//
//  Created by Bakr mohamed on 12/01/2024.
//

import Foundation

public enum AppEnvironment: String {
    case development = "Dev"
    case testing = "Testing"
    case staging = "Staging"
    case preProduction = "PreProduction"
    case production = "Production"
}

public enum RequestType {
    case REST
    case SOAP
}

public enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
    case PATCH
    case HEAD
    case OPTIONS
    case TRACE
    case CONNECT
}

public enum MultipartFormData {
    case data(Data, fileName: String, mimeType: String)
    case text(Any)
}

/// Represents the types of network requests supported by the async network layer.
public enum RequestTask {
    /// A request with no additional data in the body.
    /// Used for simple GET requests or requests where all data is in the URL or headers.
    case plain
    /// A request with URL-encoded parameters in the query string.
    /// Used for GET requests with parameters in the URL.
    case parameters(_ parameters: [String: Any])
    /// A request with a body encoded as JSON from an `Encodable` type.
    /// Used for POST or PUT requests with structured data that can be encoded as JSON.
    case encodedBody(Encodable)
    /// A request to upload a file at the provided `URL`.
    /// Used for uploading single files to a server.
    case uploadFile(URL)
    /// A multipart form request with multiple data fields and files.
    /// Used for submitting forms with multiple inputs, including files.
    case uploadMultipart([String : MultipartFormData] )
    /// A file download request.
    /// Used for downloading files from a server.
    case download(URL)
    /// A resumable download request with optional existing data and offset.
    /// Used for resuming interrupted downloads or supporting partial downloads.
    case downloadResumable(Data?, Int64?)
}

/// Enum representing the range of HTTP status codes.
///
/// The cases in this enum correspond to different ranges of HTTP status codes,
/// providing a clear categorization for better error handling.
public enum HTTPStatusCode: Int {
    /// Informational status codes (100-199).
    case information
    /// Success status codes (200-299).
    case success
    /// Redirection status codes (300-399).
    case redirection
    /// Client error status codes (404).
    case notFound
    /// Client error status codes (400-499).
    case notAuthorize
    /// Client error status codes (401).
    case clientError
    /// Server error status codes (500-599).
    case serverError
    /// Unknown status code or outside the standard HTTP ranges.
    case unknown
    
    /// Initializes an HTTPStatusCode with a raw integer value.
    ///
    /// - Parameter rawValue: The raw integer value representing an HTTP status code.
    public init?(rawValue: Int) {
        switch rawValue {
            case 100..<200:
                self = .information
            case 200..<300:
                self = .success
            case 300..<400:
                self = .redirection
            case 400..<500:
                switch rawValue{
                    case 401:
                        self = .notAuthorize
                    case 404:
                        self = .notFound
                    default:
                        self = .clientError
                }
            case 500..<600:
                self = .serverError
            default:
                self = .unknown
        }
    }
}

/// Enum representing the types of errors that can occur in the network layer.
///
/// This enum provides specific error cases for common issues that may arise during network requests.
public enum APIError: Error, Equatable {
    /// Error indicating invalid URL formation.
    case invalidURL
    /// Error indicating failure in data conversion.
    case dataConversionFailed
    /// Error indicating failure in string conversion.
    case stringConversionFailed
    /// Error representing an HTTP error with a specific status code.
    case httpError(statusCode: HTTPStatusCode)
    /// Error representing an Invalid request.
    case invalidSoapMultipartRequest
    /// Error when encode request body for SOAP request
    case xmlEncodingFailed
    /// Not Supported SOAP Operation
    case notSupportedSOAPOperation
    // No Internet
    case noNetwork
    /// Invalid Response.
    case invalidResponse

    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        return true
    }
}

extension APIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .invalidURL:
                return NSLocalizedString("Invalid URL formation.", comment: "")
            case .dataConversionFailed:
                return NSLocalizedString("Failed to convert JSON data.", comment: "")
            case .stringConversionFailed:
                return NSLocalizedString("Failed to convert string.", comment: "")
            case .httpError(let statusCode):
                return NSLocalizedString("HTTP Error with status code: \(statusCode)", comment: "")
            case .invalidSoapMultipartRequest:
                return NSLocalizedString("Invalid Request as SOAP not support MultiPart", comment: "")
            case .xmlEncodingFailed:
                return NSLocalizedString("XML encode Body Failed", comment: "")
            case .notSupportedSOAPOperation:
                return NSLocalizedString("SOAP Operation Coming Soon", comment: "")
            case .noNetwork:
                return NSLocalizedString("No Internet Connection", comment: "")
            case .invalidResponse:
                return NSLocalizedString("Invalid Response", comment: "")
        }
    }
}



