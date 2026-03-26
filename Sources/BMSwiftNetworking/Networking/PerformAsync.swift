//
//  PerformAsync.swift
//
//
//  Created by Bakr mohamed on 15/01/2024.
//

import Foundation

// MARK: - ModelTargetType

public extension ModelTargetType {

    /// Performs an asynchronous network request and returns the decoded response or throws an error.
    func performAsync() async throws -> Response {
        // check if connected to internet
        if Self.isConnectedToInternet {
            // Create URLRequest based on the target
            let urlRequest = try createRequest()
            var httpResp: HTTPURLResponse = .init()
            do {
                var urlSessionTask: URLSession {
                    if let sslConfiguration = sslPinningConfiguration {
                        let sessionDelegate = SSLPinningURLSessionDelegate(configuration: sslConfiguration)
                        return URLSession(configuration: .default, delegate: sessionDelegate, delegateQueue: nil)
                    } else {
                        return URLSession.shared
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
                        interceptor?.responseIntercept(request: urlRequest, responseData: data, response: httpResponse, error: nil)

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
                interceptor?.responseIntercept(request: urlRequest, responseData: nil, response: httpResp, error: error)
                throw error
            }
        } else {
            throw APIError.noNetwork
        }
    }

    /// Downloads a file and returns the local file URL.
    ///
    /// In **SwiftUI Previews** (`XCODE_RUNNING_FOR_PREVIEWS == "1"`) the method returns
    /// `nil` immediately without making any network call.
    ///
    /// - Returns: A `DownloadedFile` (or `nil` in Previews).
    /// - Throws: An error if there is an issue with the network request.
    func performDownload() async throws -> DownloadedFile? {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return nil
        }
        #endif

        // Check if connected to the internet
        if Self.isConnectedToInternet {
            // Create URLRequest based on the target
            let urlRequest = try createRequest()
            var httpResp: HTTPURLResponse = .init()
            do {
                // Retrieve the remote URL from the URLRequest
                guard let remoteURL = urlRequest.url else {
                    throw APIError.invalidURL
                }

                var urlSessionTask: URLSession {
                    if let sslConfiguration = sslPinningConfiguration {
                        let sessionDelegate = SSLPinningURLSessionDelegate(configuration: sslConfiguration)
                        return URLSession(configuration: .default, delegate: sessionDelegate, delegateQueue: nil)
                    } else {
                        return URLSession.shared
                    }
                }

                let response: URLResponse
                let downloadedFile: DownloadedFile

                if #available(iOS 15.0, *) {
                    // Use async/await for iOS 15 or later
                    let (downloadedURL, urlResponse) = try await urlSessionTask.download(for: urlRequest)
                    response = urlResponse

                    // Move the file to the desired location
                    downloadedFile = DownloadedFile(downloadedURL: downloadedURL, response: urlResponse, remoteURL: remoteURL)
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
                    downloadedFile = DownloadedFile(downloadedURL: downloadedURL, response: urlResponse, remoteURL: remoteURL)
                }

                // Check the HTTP status code
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.httpError(statusCode: .clientError)
                }
                httpResp = httpResponse
                // Validate the HTTP status code
                switch HTTPStatusCode(rawValue: httpResponse.statusCode) {
                case .success:
                    interceptor?.responseIntercept(request: urlRequest, responseData: nil, response: httpResponse, error: nil)
                    return downloadedFile

                default:
                    // Throw an error for other status codes
                    throw APIError.httpError(statusCode: HTTPStatusCode(rawValue: httpResponse.statusCode) ?? .clientError)
                }
            } catch {
                // Throw the encountered error
                interceptor?.responseIntercept(request: urlRequest, responseData: nil, response: httpResp, error: error)
                throw error
            }
        } else {
            throw APIError.noNetwork
        }
    }

    /// Performs a recurring asynchronous network request and returns a stream of responses.
    func performAsyncStream(repeatingEveryMinutes minutes: Double) -> AsyncThrowingStream<Response, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // Fire immediately
                    let initialResponse = try await self.performAsync()
                    continuation.yield(initialResponse)

                    while !Task.isCancelled {
                        try await Task.sleep(nanoseconds: UInt64(minutes * 60 * 1_000_000_000))
                        if Task.isCancelled { break }
                        let response = try await self.performAsync()
                        continuation.yield(response)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}

// MARK: - SuccessTargetType

public extension SuccessTargetType {

    /// Performs an asynchronous network request and returns void if successful or throws an error.
    ///
    /// In **SwiftUI Previews** (`XCODE_RUNNING_FOR_PREVIEWS == "1"`) the method returns
    /// immediately without making any network call.
    ///
    /// - Throws: An error if there is an issue with the network request or if the response is not successful.
    func performAsync() async throws -> Void {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }
        #endif

        // check if connected to internet
        if Self.isConnectedToInternet {
            do {
                // Create URLRequest based on the target
                let urlRequest = try createRequest()

                var urlSessionTask: URLSession {
                    if let sslConfiguration = sslPinningConfiguration {
                        let sessionDelegate = SSLPinningURLSessionDelegate(configuration: sslConfiguration)
                        return URLSession(configuration: .default, delegate: sessionDelegate, delegateQueue: nil)
                    } else {
                        return URLSession.shared
                    }
                }

                // Perform the asynchronous network request
                let (_, response) = try await urlSessionTask.data(for: urlRequest)

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

    /// Performs a recurring asynchronous network request and returns a stream of Void.
    ///
    /// In **SwiftUI Previews** (`XCODE_RUNNING_FOR_PREVIEWS == "1"`) the stream yields
    /// one `Void` value and finishes without making any network call.
    ///
    /// - Parameter minutes: The interval in minutes to repeat the request (e.g., 0.5 for 30 seconds).
    /// - Returns: An `AsyncThrowingStream` supplying completion events continuously.
    func performAsyncStream(repeatingEveryMinutes minutes: Double) -> AsyncThrowingStream<Void, Error> {
        AsyncThrowingStream { continuation in
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                continuation.yield(())
                continuation.finish()
                return
            }
            #endif

            let task = Task {
                do {
                    // Fire immediately
                    let initialResponse: Void = try await self.performAsync()
                    continuation.yield(initialResponse)

                    while !Task.isCancelled {
                        try await Task.sleep(nanoseconds: UInt64(minutes * 60 * 1_000_000_000))
                        if Task.isCancelled { break }
                        let response: Void = try await self.performAsync()
                        continuation.yield(response)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
