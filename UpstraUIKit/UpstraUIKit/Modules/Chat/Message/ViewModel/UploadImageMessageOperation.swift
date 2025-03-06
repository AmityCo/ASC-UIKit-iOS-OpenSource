//
//  UploadImageMessageOperation.swift
//  AmityUIKit
//
//  Created by Nutchaphon Rewik on 17/11/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import AmitySDK

class UploadImageMessageOperation: AsyncOperation {
    
    private let subChannelId: String
    private let media: AmityMedia
    private weak var repository: AmityMessageRepository?
    
    private var token: AmityNotificationToken?
    
    init(subChannelId: String, media: AmityMedia, repository: AmityMessageRepository) {
        self.subChannelId = subChannelId
        self.media = media
        self.repository = repository
    }
    
    deinit {
        token = nil
    }

    override func main() {
        
        guard let repository = repository else {
            finish()
            return
        }
        
        let channelId = self.subChannelId
        
        // Perform actual task on main queue.
        DispatchQueue.main.async {
            self.media.getImageForUploading { result in
                switch result {
                case .success(let image):
                    
                    // save image to temp directory and send local url path for uploading
                    let imageName = "\(UUID().uuidString).jpg"
                    
                    let imageUrl = FileManager.default.temporaryDirectory.appendingPathComponent(imageName)
                    let data = image.scalePreservingAspectRatio().jpegData(compressionQuality: 0.8)
                    try? data?.write(to: imageUrl)
                                        
                    let createOptions = AmityImageMessageCreateOptions(subChannelId: channelId, attachment: .localURL(url: imageUrl), fullImage: true)
                    Task { @MainActor in
                        do {
                            // This message returned is already synced with the server.
                            let message = try await repository.createImageMessage(options: createOptions)
                            self.finish()
                        } catch let error {
                            self.finish()
                            Log.warn("Error while creating image message.")
                        }
                    }                    
                case .failure:
                    self.finish()
                }
            }
            
        }
        
    }
    
}

