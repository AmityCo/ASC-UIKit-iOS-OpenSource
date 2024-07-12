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
        
        init(component: AmityNewsFeedComponent, post: AmityPostModel) {
            self.component = component
            self.post = post
        }
    }
    
    public init() {}
    
    open func goToPostDetailPage(context: AmityNewsFeedComponentBehavior.Context) {
        let vc = AmitySwiftUIHostingController(rootView: AmityPostDetailPage(post: context.post.object))
        let host = context.component.host
        host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
}
