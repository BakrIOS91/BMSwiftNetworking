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
    func performResult() async -> Result<Response, Error> {
        do {
            // Perform the asynchronous network request using performAsync
            let result = try await performAsync()
            return .success(result)
        } catch {
            // Return an error result if there was an issue with the network request or decoding
            return .failure(error)
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
    func performResult() async -> Result<Void, Error> {
        do {
            // Perform the asynchronous network request using performAsync
            let result: Void = try await performAsync()
            return .success(result)
        } catch {
            // Return an error result if there was an issue with the network request or if the response is not successful
            return .failure(error)
        }
    }
}

