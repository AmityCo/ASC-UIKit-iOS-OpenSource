//
//  AmityNewsFeedComponentBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 7/9/24.
//

import Foundation

open class AmityNewsFeedComponentBehavior {
    
    open class Context {
        public let component: AmityNewsFeedComponent
        public let post: AmityPostModel
        public let showPollResult: Bool
        
        init(component: AmityNewsFeedComponent, post: AmityPostModel, showPollResult: Bool = false) {
            self.component = component
            self.post = post
            self.showPollResult = showPollResult
        }
    }
    
    public init() {}
    
    open func goToPostDetailPage(context: AmityNewsFeedComponentBehavior.Context) {
        let postComponentContext = AmityPostContentComponent.Context(shouldShowPollResults: context.showPollResult, category: context.post.isPinned ? .global : .general)
        let vc = AmitySwiftUIHostingController(rootView: AmityPostDetailPage(post: context.post.object, context: postComponentContext))
        let host = context.component.host
        host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
}
