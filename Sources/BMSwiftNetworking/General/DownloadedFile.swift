//
//  DownloadedFile.swift
//  BMSwiftNetworking
//
//  Created by SherifAshraf on 18/12/2024.
//

import Foundation

public struct DownloadedFile: Codable {
    public let downloadedURL: URL?
    public var response: URLResponse? = nil
    public let remoteURL: URL?

    public init(downloadedURL: URL? = nil, response: URLResponse? = nil, remoteURL: URL? = nil) {
        self.downloadedURL = downloadedURL
        self.response = response
        self.remoteURL = remoteURL
    }

    enum CodingKeys: String, CodingKey {
        case downloadedURL
        case remoteURL
    }
}
