//
//  NetworkInterceptor.swift
//
//
//  Created by Bakr mohamed on 15/01/2024.
//

import Foundation

/// Protocol defining network interception for requests and responses.
/// Conform to this protocol to provide custom logging, request adaptation, or metrics.
public protocol NetworkInterceptor {
    /// Called before a request is sent.
    func requestIntercept(_ request: URLRequest)
    
    /// Called after a response is received or an error occurs.
    func responseIntercept(request: URLRequest, responseData: Data?, response: HTTPURLResponse?, error: Error?)
}

/// Default implementations to make interception methods optional for conforming types.
public extension NetworkInterceptor {
    func requestIntercept(_ request: URLRequest) {}
    func responseIntercept(request: URLRequest, responseData: Data?, response: HTTPURLResponse?, error: Error?) {}
}
