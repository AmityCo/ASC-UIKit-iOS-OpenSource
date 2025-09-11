//
//  AmityPostSearchResultComponentBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/2/25.
//

open class AmityPostSearchResultComponentBehavior {
    
    open class Context {
        public let component: AmityPostSearchResultComponent
        public let post: AmityPostModel
        public let showPollResult: Bool
        
        init(component: AmityPostSearchResultComponent, post: AmityPostModel, showPollResult: Bool = false) {
            self.component = component
            self.post = post
            self.showPollResult = showPollResult
        }
    }
    
    public init() {}
    
    open func goToPostDetailPage(context: AmityPostSearchResultComponentBehavior.Context) {
        let postComponentContext = AmityPostContentComponent.Context(shouldShowPollResults: context.showPollResult, category: context.post.isPinned ? .global : .general)
        let vc = AmitySwiftUIHostingController(rootView: AmityPostDetailPage(post: context.post.object, context: postComponentContext))
        let host = context.component.host
        host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
}
