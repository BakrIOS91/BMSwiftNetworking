//
//  URLRequest+Ext.swift
//
//
//  Created by Bakr mohamed on 15/01/2024.
//

import Foundation
/// An extension on `URLRequest` to pretty-print URL parameters.
extension URLRequest {
    /// Extracts and pretty-prints the URL parameters from the request.
    ///
    /// This method parses the URL of the request and extracts its query parameters,
    /// then formats them in a readable string.
    ///
    /// - Returns: A string containing the pretty-printed URL parameters,
    ///            or `nil` if there are no parameters.
    func prettyPrintURLParameters() -> String? {
        // Ensure that the request has a valid URL and can be parsed into components
        guard let url = self.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        var outputString = ""

        // Check if the URL has query items
        if let queryItems = components.queryItems {
            // Iterate through query items and construct the pretty-printed string
            for queryItem in queryItems {
                // Percent-encode the name and value for use in URLs
                if let encodedName = queryItem.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let encodedValue = queryItem.value?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    outputString += "\n\(encodedName) = \(encodedValue)"
                }
            }
        }

        // Return the pretty-printed string, or `nil` if there are no parameters
        return outputString.isEmpty ? nil : outputString
    }
}
