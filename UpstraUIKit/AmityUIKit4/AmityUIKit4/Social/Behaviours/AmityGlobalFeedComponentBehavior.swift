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
        
        init(component: AmityGlobalFeedComponent, post: AmityPostModel) {
            self.component = component
            self.post = post
        }
    }
    
    public init() {}
    
    open func goToPostDetailPage(context: AmityGlobalFeedComponentBehavior.Context) {
        let vc = AmitySwiftUIHostingController(rootView: AmityPostDetailPage(post: context.post.object))
        let host = context.component.host
        host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
}
