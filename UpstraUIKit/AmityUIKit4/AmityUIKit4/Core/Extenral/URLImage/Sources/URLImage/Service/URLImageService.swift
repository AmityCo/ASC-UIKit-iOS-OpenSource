//
//  URLImageService.swift
//  
//
//  Created by Dmytro Anokhin on 25/08/2020.
//

import Foundation
import CoreGraphics
import Combine

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public class URLImageService {
    public static let defaultImageService = URLImageService(fileStore: URLImageFileStore(), inMemoryStore: URLImageInMemoryStore())
    
    
    public init(fileStore: URLImageFileStoreType? = nil, inMemoryStore: URLImageInMemoryStoreType? = nil) {
        self.fileStore = fileStore
        self.inMemoryStore = inMemoryStore
    }

    public let fileStore: URLImageFileStoreType?

    public let inMemoryStore: URLImageInMemoryStoreType?

    // MARK: - Internal

    let downloadManager = DownloadManager()
}
