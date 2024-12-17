//
//  URL+Ext.swift
//  BMSwiftNetworking
//
//  Created by SherifAshraf on 17/12/2024.
//

import Foundation

extension URL {
    func getMimeType() -> String {
        let pathExtension = self.pathExtension.lowercased()
        switch pathExtension {
        case "pdf": return "application/pdf"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "doc" : return "application/msword"
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        default: return "application/octet-stream"
        }
    }
}
