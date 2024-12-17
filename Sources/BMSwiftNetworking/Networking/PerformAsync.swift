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
    
    /// Downloads a file and returns the local file URL.
    ///
    /// - Returns: A URL pointing to the downloaded file.
    /// - Throws: An error if there is an issue with the network request.
    func performDownload() async throws -> URL? {
         // Check if connected to the internet
         if Self.isConnectedToInternet {
             // Create URLRequest based on the target
             let urlRequest = try createRequest()
             var httpResp: HTTPURLResponse = .init()
             do {
                 // Retrieve the remote URL from the URLRequest
                 guard let remoteURL = urlRequest.url else {
                     throw APIError.invalidURL // Create this error type as needed
                 }

                 var urlSessionTask: URLSession {
                     if self.sslCertificates.isEmpty {
                         return URLSession.shared
                     } else {
                         let sessionDelegate = SSLPinningURLSessionDelegate(sslCertificates: sslCertificates)
                         return URLSession(configuration: .default, delegate: sessionDelegate, delegateQueue: nil)
                     }
                 }

                 let response: URLResponse
                 let finalDestinationURL: URL

                 if #available(iOS 15.0, *) {
                     // Use async/await for iOS 15 or later
                     let (downloadedURL, urlResponse) = try await urlSessionTask.download(for: urlRequest)
                     response = urlResponse
                     
                     // Move the file to the desired location
                     finalDestinationURL = try returnFinalDestinationURL(from: downloadedURL, remoteURL: remoteURL)
                 } else {
                     // Fallback for earlier iOS versions using completion handlers
                     let (downloadedURL, urlResponse): (URL, URLResponse) = try await withCheckedThrowingContinuation { continuation in
                         urlSessionTask.downloadTask(with: urlRequest) { localURL, urlResponse, error in
                             if let error = error {
                                 continuation.resume(throwing: error)
                                 return
                             }
                             guard let localURL = localURL, let urlResponse = urlResponse else {
                                 continuation.resume(throwing: APIError.invalidResponse)
                                 return
                             }
                             continuation.resume(returning: (localURL, urlResponse))
                         }.resume()
                     }
                 
                     response = urlResponse
                     // Move the file to the desired location
                     finalDestinationURL = try returnFinalDestinationURL(from: downloadedURL, remoteURL: remoteURL)
                 }

                 // Check the HTTP status code
                 guard let httpResponse = response as? HTTPURLResponse else {
                     throw APIError.httpError(statusCode: .clientError)
                 }
                 httpResp = httpResponse
                 // Validate the HTTP status code
                 switch HTTPStatusCode(rawValue: httpResponse.statusCode) {
                 case .success:
                     responseLogger(request: urlRequest, responseData: nil, response: httpResponse)

                     return finalDestinationURL

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

     /// Saves a downloaded file to a desired location and returns the final URL.
     ///
     /// - Parameters:
     ///   - downloadedURL: The temporary URL of the downloaded file.
     ///   - remoteURL: The remote URL from which the file was downloaded.
     /// - Returns: The final destination URL of the file.
     private func returnFinalDestinationURL(from downloadedURL: URL, remoteURL: URL) throws -> URL {
         // Get the MIME type or derive it from the URL
         let mimeType = remoteURL.getMimeType()
         let fileExtension = mimeType.fileExtension()

         // Extract the original file name from the remote URL
         let originalFileName = remoteURL.lastPathComponent
         let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(originalFileName + ".\(fileExtension)")
         return destinationURL
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
