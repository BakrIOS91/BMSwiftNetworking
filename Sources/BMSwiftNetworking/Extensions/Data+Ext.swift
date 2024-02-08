//
//  File.swift
//  
//
//  Created by Bakr mohamed on 14/01/2024.
//

import Foundation
public extension Data {
    
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
    
    var prettyPrintedJSONString: String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
              let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
              let jsonString = String(data: jsonData, encoding: .utf8)
        else {
            return nil
        }
        return jsonString
    }
    
    var prettyPrintedDescription: String {
        if let jsonString = String(data: self, encoding: .utf8) {
            return jsonString
        } else {
            let byteCount = self.count
            return "\(byteCount) bytes"
        }
    }
}
