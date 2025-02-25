//
//  AmityGlobalFeedComponentBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/10/24.
//

import Foundation

open class AmityGlobalFeedComponentBehavior {
    
    open class Context {
        public let component: AmityGlobalFeedComponent
        public let post: AmityPostModel
        public let showPollResult: Bool
        
        init(component: AmityGlobalFeedComponent, post: AmityPostModel, showPollResult: Bool = false) {
            self.component = component
            self.post = post
            self.showPollResult = showPollResult
        }
    }
    
    public init() {}
    
    open func goToPostDetailPage(context: AmityGlobalFeedComponentBehavior.Context) {
        
        let postComponentContext = AmityPostContentComponent.Context(shouldShowPollResults: context.showPollResult)
        let vc = AmitySwiftUIHostingController(rootView: AmityPostDetailPage(post: context.post.object, context: postComponentContext))
        let host = context.component.host
        host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
}
