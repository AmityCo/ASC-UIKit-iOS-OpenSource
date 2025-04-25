//
//  AmityNotificationTrayPageBehavior.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 2/4/25.
//

open class AmityNotificationTrayPageBehavior {
    
    open class Context {
        public let page: AmityNotificationTrayPage
        public let postId: String?
        public let commentId: String?
        public let parentCommentId: String?
        public let communityId: String?
        
        public init(page: AmityNotificationTrayPage, postId: String?, commentId: String?, parentCommentId: String?, communityId: String?) {
            self.page = page
            self.postId = postId
            self.commentId = commentId
            self.parentCommentId = parentCommentId
            self.communityId = communityId
        }
    }
    
    public init() { }
    
    open func goToPostDetailPage(context: AmityNotificationTrayPageBehavior.Context) {
        let page = AmityPostDetailPage(id: context.postId ?? "", commentId: context.commentId, parentId: context.parentCommentId)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
    open func goToCommunityProfilePage(context: AmityNotificationTrayPageBehavior.Context) {
        
        let page = AmityCommunityProfilePage(communityId: context.communityId ?? "")
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
}
