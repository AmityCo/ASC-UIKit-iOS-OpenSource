//
//  CreateStream.swift
//  AmityUIKitLiveStream
//
//  Created by Nutchaphon Rewik on 2/9/2564 BE.
//

import Foundation
import AmitySDK

extension GoLive {
    
    class CreateStream: AsyncOperation {
        
        var result: Result<AmityStream, Error>?
        
        private let streamRepository: AmityStreamRepository
        private let title: String
        private let streamDescription: String?
        private let meta: [String: Any]?
        
        init(streamRepository: AmityStreamRepository,
             title: String,
             description: String?,
             meta: [String : Any]?) {
            
            self.streamRepository = streamRepository
            self.title = title
            self.streamDescription = description
            self.meta = meta
            
        }
        
        override func main() {
            
            let coverImageData = findOptionalCoverImageData()
            
            Task { @MainActor in
                do {
                    let stream = try await streamRepository.createStream(withTitle: title, description: streamDescription, thumbnailImage: coverImageData, meta: meta)
                    self.result = .success(stream)
                    self.finish()
                } catch let error {
                    self.result = .failure(error)
                    self.finish()
                }
            }
        }
        
        private func findOptionalCoverImageData() -> AmityImageData? {
            // Find result from dependencies.
            for dependency in dependencies {
                if let uploadCoverImage = dependency as? UploadCoverImage {
                    return uploadCoverImage.getCoverImageData()
                }
            }
            return nil
        }
        
    }
    
}

