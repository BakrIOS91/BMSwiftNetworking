//
//  Target.swift
//
//
//  Created by Bakr mohamed on 15/01/2024.
//

import Foundation

/// Protocol defining the properties required for a target in the network layer.
public protocol Target {
    /// The environment in which the app is running.
    var appEnvironment: AppEnvironment { get set }
    
    /// The host for the app.
    var kAppHost: String { get }
    
    /// The main API path for the app.
    var kMainAPIPath: String? { get }
    
    /// The scheme used by the app.
    var kAppScheme: String { get }
    
    /// The port used by the app (if applicable).
    var kAppPort: Int?  { get }
    
    /// The base URL components for the app's network requests.
    var kBaseURLComponents: URLComponents { get }
    
    /// The base URL for the app's network requests.
    var kBaseURL: String { get }
}

public extension Target {
    /// The default main API path is nil.
    var kMainAPIPath: String? { nil }
    
    /// The port used by the app (if applicable).
    var kAppPort: Int?  { nil }
    
    /// The default implementation of base URL components.
    var kBaseURLComponents: URLComponents {
        var urlComponents = URLComponents()
        urlComponents.scheme = kAppScheme
        
        // Set the host, incorporating the main API path if present
        if let apiPath = kMainAPIPath {
            urlComponents.path = "/" + apiPath // Add a leading slash for a valid path
        } else {
            urlComponents.path = "/" // Set an empty path explicitly
        }
        
        // Set the port if applicable
        if let port = kAppPort {
            urlComponents.port = port
        }
        return urlComponents
    }
    
    /// The default implementation of the base URL.
    var kBaseURL: String {
        return kBaseURLComponents.url?.absoluteString ?? ""
    }
}

