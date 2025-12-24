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
        public let userId: String?
        public let eventId: String?
        public let roomId: String?
        
        public init(
            page: AmityNotificationTrayPage,
            postId: String?,
            commentId: String?,
            parentCommentId: String?,
            communityId: String?,
            userId: String?,
            eventId: String? = nil,
            roomId: String? = nil
        ) {
            self.page = page
            self.postId = postId
            self.commentId = commentId
            self.parentCommentId = parentCommentId
            self.communityId = communityId
            self.userId = userId
            self.eventId = eventId
            self.roomId = roomId
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
    
    open func goToUserProfilePage(context: AmityNotificationTrayPageBehavior.Context) {
        let page = AmityUserProfilePage(userId: context.userId ?? "")
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
    open func goToEventDetailPage(context: AmityNotificationTrayPageBehavior.Context) {
        
        let page = AmityEventDetailPage(eventId: context.eventId ?? "")
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
    open func goToLiveStreamPage(context: AmityNotificationTrayPageBehavior.Context) {
        let livestreamPlayerPage = AmityLivestreamPlayerPage(roomId: context.roomId ?? "", displayErrorIfEnded: true)
        let hostController = AmitySwiftUIHostingNavigationController(rootView: livestreamPlayerPage)
        hostController.isNavigationBarHidden = true
        hostController.modalPresentationStyle = .overFullScreen
        context.page.host.controller?.present(hostController, animated: true)
    }
}
