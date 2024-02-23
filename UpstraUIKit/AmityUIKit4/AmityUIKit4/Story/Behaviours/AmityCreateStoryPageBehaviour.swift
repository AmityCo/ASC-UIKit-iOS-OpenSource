//
//  CameraPageBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/18/23.
//

import Foundation
import SwiftUI

open class AmityCreateStoryPageBehaviour {
    open class Context {
        public let page: AmityCreateStoryPage
        public var targetId: String
        public var avatar: URL?
        public var outputImage: (UIImage?, URL?)
        public var outputVideo: URL?
        
        init(page: AmityCreateStoryPage, targetId: String, avatar: URL?, outputImage: (UIImage?, URL?) = (nil, nil), outputVideo: URL? = nil) {
            self.page = page
            self.targetId = targetId
            self.avatar = avatar
            self.outputImage = outputImage
            self.outputVideo = outputVideo
        }
    }
    
    public init() {}
    
    open func goToDraftStoryPage(context: AmityCreateStoryPageBehaviour.Context) {
        
        var mediaType: StoryMediaType?
        
        if let videoURL = context.outputVideo {
            mediaType = .video(videoURL)
        } else if let image = context.outputImage.0,
                  let imageURL = context.outputImage.1 {
            mediaType = .image(imageURL, image)
        }
        
        guard let mediaType else {
            return
        }
        
        let draftStoryPage = AmityDraftStoryPage(targetId: context.targetId, avatar: context.avatar, mediaType: mediaType)
        let controller = SwiftUIHostingController(rootView: draftStoryPage)
        
        let sourceController = context.page.host.controller?.navigationController
        sourceController?.pushViewController(controller, animated: true)
        
    }
    
}
