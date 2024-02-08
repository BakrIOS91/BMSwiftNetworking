//
//  Dictionary+Ext.swift
//  
//
//  Created by Bakr mohamed on 28/03/2023.
//

import Foundation

public extension Dictionary {
    var jsonData: Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
    }
    
    static func +=(lhs: inout Self, rhs: Self) {
        lhs.merge(rhs) { _ , new in new }
    }
    static func +=<S: Sequence>(lhs: inout Self, rhs: S) where S.Element == (Key, Value) {
        lhs.merge(rhs) { _ , new in new }
    }
    
    /// Convert Dictionary to JSON string
    /// - Throws: exception if dictionary cannot be converted to JSON data or when data cannot be converted to UTF8 string
    /// - Returns: JSON string
    func toJson() throws -> String {
        let data = try JSONSerialization.data(withJSONObject: self)
        if let string = String(data: data, encoding: .utf8) {
            return string
        }
        throw NSError(domain: "Dictionary", code: 1, userInfo: ["message": "Data cannot be converted to .utf8 string"])
    }
}
