//
//  PerformResult.swift
//
//
//  Created by Bakr mohamed on 15/01/2024.
//

import Foundation

/// Extension for `ModelTargetType` protocol providing a convenience method to perform an asynchronous
/// network request and return the result as a `Result` type.
public extension ModelTargetType {
    
    /// Performs an asynchronous network request and returns the result.
    ///
    /// This method wraps the `performAsync` method in a `Result` type, providing a convenient way to
    /// handle the result of the network request.
    ///
    /// - Returns: A `Result` containing the decoded response or an error.
    ///
    /// Example usage:
    /// ```
    /// let result: Result<YourModelType, Error> = try await yourModelTarget.performResult()
    /// ```
    ///
    /// - Throws: An error if there is an issue with the network request or decoding the response.
    func performResult() async -> Result<Response, APIError> {
        do {
            // Perform the asynchronous network request using performAsync
            let result = try await performAsync()
            return .success(result)
        } catch let apiError as APIError {
            // Return an APIError if there was an issue with the network request or decoding
            return .failure(apiError)
        } catch {
            // Handle any other unexpected errors
            return .failure(.httpError(statusCode: .clientError))
        }
    }
    
    func performDownloadResult() async -> Result<DownloadedFile?, APIError> {
        do {
            // Perform the asynchronous network request using performAsync
            let result = try await performDownload()
            return .success(result)
        } catch let apiError as APIError {
            // Return an APIError if there was an issue with the network request or decoding
            return .failure(apiError)
        } catch {
            // Handle any other unexpected errors
            return .failure(.httpError(statusCode: .clientError))
        }
    }
    
    /// Performs a recurring asynchronous network request and returns the stream of `Result` types.
    /// - Parameter seconds: The interval in seconds to repeat the request.
    /// - Returns: An `AsyncStream` yielding the continuous results.
    func performResultStream(repeatingEverySeconds seconds: Double) -> AsyncStream<Result<Response, APIError>> {
        AsyncStream { continuation in
            let task = Task {
                // Fire immediately
                let initialResult = await self.performResult()
                continuation.yield(initialResult)
                
                while !Task.isCancelled {
                    do {
                        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                    } catch {
                        break // sleep interrupted, task cancelled
                    }
                    if Task.isCancelled { break }
                    let result = await self.performResult()
                    continuation.yield(result)
                }
                continuation.finish()
            }
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}

/// Extension for `SuccessTargetType` protocol providing a convenience method to perform an asynchronous
/// network request and return the result as a `Result` type.
public extension SuccessTargetType {
    
    /// Performs an asynchronous network request and returns the result.
    ///
    /// This method wraps the `performAsync` method in a `Result` type, providing a convenient way to
    /// handle the result of the network request when success is expected.
    ///
    /// - Returns: A `Result` indicating success or an error.
    ///
    /// Example usage:
    /// ```
    /// let result: Result<Void, Error> = try await yourSuccessTarget.performResult()
    /// ```
    ///
    /// - Throws: An error if there is an issue with the network request or if the response is not successful.
    func performResult() async -> Result<Void, APIError> {
        do {
            // Perform the asynchronous network request using performAsync
            let result: Void = try await performAsync()
            return .success(result)
        } catch let apiError as APIError {
            // Return an APIError if there was an issue with the network request or decoding
            return .failure(apiError)
        } catch {
            // Handle any other unexpected errors
            return .failure(.httpError(statusCode: .clientError))
        }
    }
    
    /// Performs a recurring asynchronous network request and returns the stream of `Result` types.
    /// - Parameter seconds: The interval in seconds to repeat the request.
    /// - Returns: An `AsyncStream` yielding the continuous results.
    func performResultStream(repeatingEverySeconds seconds: Double) -> AsyncStream<Result<Void, APIError>> {
        AsyncStream { continuation in
            let task = Task {
                // Fire immediately
                let initialResult = await self.performResult()
                continuation.yield(initialResult)
                
                while !Task.isCancelled {
                    do {
                        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                    } catch {
                        break // sleep interrupted, task cancelled
                    }
                    if Task.isCancelled { break }
                    let result = await self.performResult()
                    continuation.yield(result)
                }
                continuation.finish()
            }
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}

