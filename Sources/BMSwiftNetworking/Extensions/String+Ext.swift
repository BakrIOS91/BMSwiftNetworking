//
//  String+Ext.swift
//  BMSwiftNetworking
//
//  Created by SherifAshraf on 17/12/2024.
//

import Foundation

extension String {
    /// Converts a MIME type to its corresponding file extension.
    /// Defaults to "dat" if the MIME type is not recognized.
    func fileExtension() -> String {
        let mimeTypeToExtensionMap: [String: String] = [
            "application/pdf": "pdf",
            "application/msword": "doc",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
            "image/png": "png",
            "image/jpeg": "jpg"
        ]
        return mimeTypeToExtensionMap[self] ?? "dat"
    }
}
