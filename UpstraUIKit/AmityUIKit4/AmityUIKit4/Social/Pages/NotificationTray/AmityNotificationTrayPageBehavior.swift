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
        /// NEW in v4 — L0 root comment ID for L2 reply notifications.
        /// Null for L0/L1 notification targets.
        public let rootCommentId: String?
        public let communityId: String?
        public let userId: String?
        public let eventId: String?
        public let roomId: String?
        
        public init(
            page: AmityNotificationTrayPage,
            postId: String?,
            commentId: String?,
            parentCommentId: String?,
            rootCommentId: String? = nil,
            communityId: String?,
            userId: String?,
            eventId: String? = nil,
            roomId: String? = nil
        ) {
            self.page = page
            self.postId = postId
            self.commentId = commentId
            self.parentCommentId = parentCommentId
            self.rootCommentId = rootCommentId
            self.communityId = communityId
            self.userId = userId
            self.eventId = eventId
            self.roomId = roomId
        }
    }
    
    public init() { }
    
    open func goToPostDetailPage(context: AmityNotificationTrayPageBehavior.Context) {
        // Preload the reply thread when the notification target is a reply (parentCommentId is set),
        // so the thread is auto-expanded and the target bubble is visible without manual interaction.
        let page = AmityPostDetailPage(
            id: context.postId ?? "",
            commentId: context.commentId,
            parentId: context.parentCommentId,
            rootCommentId: context.rootCommentId,
            preloadRepliesOfComment: context.parentCommentId != nil
        )
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
    
    open func goToEditProfilePage(context: AmityNotificationTrayPageBehavior.Context) {
        let page = AmityEditUserProfilePage()
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
