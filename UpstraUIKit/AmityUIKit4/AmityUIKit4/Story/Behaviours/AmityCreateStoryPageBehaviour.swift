//
//  CameraPageBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/18/23.
//

import Foundation
import SwiftUI
import AmitySDK

open class AmityCreateStoryPageBehaviour {
    open class Context {
        public let page: AmityCreateStoryPage
        public var targetId: String
        public var targetType: AmityStoryTargetType
        public var outputImage: (UIImage?, URL?)
        public var outputVideo: URL?
        
        init(page: AmityCreateStoryPage, targetId: String, targetType: AmityStoryTargetType, outputImage: (UIImage?, URL?) = (nil, nil), outputVideo: URL? = nil) {
            self.page = page
            self.targetId = targetId
            self.targetType = targetType
            self.outputImage = outputImage
            self.outputVideo = outputVideo
        }
    }
    
    public init() {}
    
    open func goToDraftStoryPage(context: AmityCreateStoryPageBehaviour.Context) {
        
        var mediaType: AmityStoryMediaType?
        
        if let videoURL = context.outputVideo {
            mediaType = .video(videoURL)
        } else if let imageURL = context.outputImage.1 {
            mediaType = .image(imageURL)
        }
        
        guard let mediaType else {
            return
        }
        
        let draftStoryPage = AmityDraftStoryPage(targetId: context.targetId, targetType: context.targetType, mediaType: mediaType)
        let controller = AmitySwiftUIHostingController(rootView: draftStoryPage)
        
        let sourceController = context.page.host.controller?.navigationController
        sourceController?.pushViewController(controller, animated: true)
        
    }
    
}
