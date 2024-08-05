//
//  File.swift
//  
//
//  Created by Bakr mohamed on 15/01/2024.
//

import Foundation

// Implement the perform extension on ModelTargetType
public extension ModelTargetType {
    /// Performs an asynchronous network request and returns the decoded response or throws an error.
    ///
    /// - Returns: The decoded response.
    /// - Throws: An error if there is an issue with the network request or decoding the response.
    func performAsync() async throws -> Response {
        // check if connected to internet
        if Self.isConnectedToInternet {
            // Create URLRequest based on the target
            let urlRequest = try createRequest()
            var httpResp: HTTPURLResponse = .init()
            do {
                
                var urlSessionTask: URLSession {
                    if self.sslCertificates.isEmpty {
                        return URLSession.shared
                    } else {
                        let sessionDelegate = SSLPinningURLSessionDelegate(sslCertificates: sslCertificates)
                        return URLSession(configuration: .default, delegate: sessionDelegate, delegateQueue: nil)
                    }
                }
                
                // Perform the asynchronous network request
                let (data, response) = try await urlSessionTask.data(for: urlRequest)
                
                // Check the HTTP status code
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.httpError(statusCode: .clientError)
                }
                httpResp = httpResponse
                // Handle different status code ranges
                switch HTTPStatusCode(rawValue: httpResponse.statusCode) {
                    case .success:
                        // Decode the response using JSONDecoder
                        let decoder = JSONDecoder()
                        responseLogger(request: urlRequest, responseData: data,response: httpResponse)
                        
                        do {
                            let decodedResponse = try decoder.decode(Response.self, from: data)
                            // Return the decoded response
                            return decodedResponse
                        } catch {
                            // Throw an error for decoding failures
                            throw APIError.dataConversionFailed
                        }
                        
                    default:
                        // Throw an error for other status codes
                        throw APIError.httpError(statusCode: HTTPStatusCode(rawValue: httpResponse.statusCode) ?? .clientError)
                }
            } catch {
                // Throw the encountered error
                responseLogger(request: urlRequest, response: httpResp, error: error)
                throw error
            }
        } else {
            throw APIError.noNetwork
        }
    }
}

// Implement the perform extension on SuccessTargetType
public extension SuccessTargetType {
    /// Performs an asynchronous network request and returns void if successful or throws an error.
    ///
    /// - Throws: An error if there is an issue with the network request or if the response is not successful.
    func performAsync() async throws -> Void {
        // check if connected to internet
        if Self.isConnectedToInternet {
            do {
                // Create URLRequest based on the target
                let urlRequest = try createRequest()
                
                var urlSessionTask: URLSession {
                    if self.sslCertificates.isEmpty {
                        return URLSession.shared
                    } else {
                        let sessionDelegate = SSLPinningURLSessionDelegate(sslCertificates: sslCertificates)
                        return URLSession(configuration: .default, delegate: sessionDelegate, delegateQueue: nil)
                    }
                }
                
                // Perform the asynchronous network request
                let (data, response) = try await urlSessionTask.data(for: urlRequest)
                
                // Check the HTTP status code
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.httpError(statusCode: .clientError)
                }
                
                // Handle different status code ranges
                switch HTTPStatusCode(rawValue: httpResponse.statusCode) {
                    case .success:
                        return ()
                        
                    default:
                        // Throw an error for other status codes
                        throw APIError.httpError(statusCode: HTTPStatusCode(rawValue: httpResponse.statusCode) ?? .clientError)
                }
            } catch {
                // Throw the encountered error
                throw error
            }
        } else {
            throw APIError.noNetwork
        }
    }
}
