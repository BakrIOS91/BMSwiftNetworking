//
//  PerformPublisher.swift
//
//
//  Created by Bakr mohamed on 15/01/2024.
//

import Foundation
import Combine

/// Extension for `ModelTargetType` protocol providing a convenience method to perform an asynchronous
/// network request and return the result as a Combine `AnyPublisher`.
public extension ModelTargetType {
    
    /// Performs an asynchronous network request and returns the result as a Combine `AnyPublisher`.
    ///
    /// This method uses Combine's `Future` to wrap the `performAsync` method and convert the result into
    /// an `AnyPublisher` for easy integration with Combine-based workflows.
    ///
    /// - Returns: An `AnyPublisher` containing the decoded response or an error.
    ///
    /// Example usage:
    /// ```
    /// let publisher: AnyPublisher<YourModelType, Error> = yourModelTarget.performPublisher()
    /// ```
    func performPublisher() -> AnyPublisher<Response, APIError> {
        return Future<Response, APIError> { promise in
            Task {
                do {
                    // Perform the asynchronous network request using performAsync
                    let result = try await performAsync()
                    promise(.success(result))
                } catch let apiError as APIError {
                    // Return an APIError if there was an issue with the network request or decoding
                    promise(.failure(apiError))
                } catch {
                    // Handle any other unexpected errors
                    promise(.failure(.httpError(statusCode: .clientError)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Performs a recurring asynchronous network request and returns the result as a Combine `AnyPublisher`.
    /// - Parameter minutes: The interval in minutes to repeat the request (e.g., 0.5 for 30 seconds).
    /// - Returns: An `AnyPublisher` containing the decoded responses or an error.
    func performPublisher(repeatingEveryMinutes minutes: Double) -> AnyPublisher<Response, APIError> {
        let intervalSeconds = minutes * 60
        return Timer.publish(every: intervalSeconds, on: .main, in: .common)
            .autoconnect()
            .prepend(Date())
            .setFailureType(to: APIError.self)
            .flatMap { _ in
                self.performPublisher()
            }
            .eraseToAnyPublisher()
    }
}

/// Extension for `SuccessTargetType` protocol providing a convenience method to perform an asynchronous
/// network request and return the result as a Combine `AnyPublisher`.
public extension SuccessTargetType {
    
    /// Performs an asynchronous network request and returns the result as a Combine `AnyPublisher`.
    ///
    /// This method uses Combine's `Future` to wrap the `performAsync` method and convert the result into
    /// an `AnyPublisher` for easy integration with Combine-based workflows.
    ///
    /// - Returns: An `AnyPublisher` indicating success or an error.
    ///
    /// Example usage:
    /// ```
    /// let publisher: AnyPublisher<Void, Error> = yourSuccessTarget.performPublisher()
    /// ```
    func performPublisher() -> AnyPublisher<Void, APIError> {
        return Future<Void, APIError> { promise in
            Task {
                do {
                    // Perform the asynchronous network request using performAsync
                    let result: Void = try await performAsync()
                    promise(.success(result))
                } catch let apiError as APIError {
                    // Return an APIError if there was an issue with the network request or decoding
                    promise(.failure(apiError))
                } catch {
                    // Handle any other unexpected errors
                    promise(.failure(.httpError(statusCode: .clientError)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Performs a recurring asynchronous network request and returns the result as a Combine `AnyPublisher`.
    /// - Parameter minutes: The interval in minutes to repeat the request (e.g., 0.5 for 30 seconds).
    /// - Returns: An `AnyPublisher` indicating success or an error.
    func performPublisher(repeatingEveryMinutes minutes: Double) -> AnyPublisher<Void, APIError> {
        let intervalSeconds = minutes * 60
        return Timer.publish(every: intervalSeconds, on: .main, in: .common)
            .autoconnect()
            .prepend(Date())
            .setFailureType(to: APIError.self)
            .flatMap { _ in
                self.performPublisher()
            }
            .eraseToAnyPublisher()
    }
}
