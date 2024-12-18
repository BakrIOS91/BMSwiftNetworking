//
//  DownloadedFile.swift
//  BMSwiftNetworking
//
//  Created by SherifAshraf on 18/12/2024.
//

import Foundation

public struct DownloadedFile {
    let downloadedURL: URL?
    let response: URLResponse?
    let remoteURL: URL?
    
    public init(downloadedURL: URL? = nil, response: URLResponse? = nil, remoteURL: URL? = nil) {
        self.downloadedURL = downloadedURL
        self.response = response
        self.remoteURL = remoteURL
    }
}
