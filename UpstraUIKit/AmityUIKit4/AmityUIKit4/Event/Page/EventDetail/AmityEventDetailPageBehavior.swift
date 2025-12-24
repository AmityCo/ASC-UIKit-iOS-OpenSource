//
//  AmityEventDetailPageBehavior.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 10/11/25.
//

import SwiftUI
import AmitySDK

open class AmityEventDetailPageBehavior {
    
    open class Context {
        let page: AmityEventDetailPage
        let event: AmityEvent
        let showPollResult: Bool
        
        public init(page: AmityEventDetailPage, event: AmityEvent, showPollResult: Bool = false) {
            self.page = page
            self.event = event
            self.showPollResult = showPollResult
        }
    }
    
    public init() { }
    
    open func goToEventSetupPage(context: AmityEventDetailPageBehavior.Context) {
        let setupPage = AmityEventSetupPage(mode: .edit(event: context.event))
        let controller = AmitySwiftUIHostingController(rootView: setupPage)

        context.page.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }

    open func goToLivestreamPostComposerPage(context: AmityEventDetailPageBehavior.Context) {
        let page = AmityCreateLivestreamPage(event: context.event)
        let vc = AmitySwiftUIHostingController(rootView: page)
        
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        navController.navigationBar.isHidden = true
        
        context.page.host.controller?.present(navController, animated: true)
    }

    open func goToPostDetailPage(context: AmityEventDetailPageBehavior.Context, post: AmityPostModel?, category: AmityPostCategory = .general) {
        if let post = post {
            let postComponentContext = AmityPostContentComponent.Context(shouldShowPollResults: context.showPollResult, category: category, shouldHideTarget: true)
            let vc = AmitySwiftUIHostingController(rootView: AmityPostDetailPage(post: post.object, context: postComponentContext))
            let host = context.page.host
            host.controller?.navigationController?.pushViewController(vc, animated: true)
        }
    }

    open func goToPostComposerPage(context: AmityEventDetailPageBehavior.Context) {
        let createOptions: AmityPostComposerOptions

        createOptions = AmityPostComposerOptions.createOptions(targetId: context.event.discussionCommunityId, targetType: .community, community: nil, event: context.event)
        
        let view = AmityPostComposerPage(options: createOptions)
        let controller = AmitySwiftUIHostingController(rootView: view)
        
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.navigationBar.isHidden = true
        
        context.page.host.controller?.present(navigationController, animated: true)
    }

    open func goToPollPostComposerPage(context: AmityEventDetailPageBehavior.Context, pollType: AmityPollType) {
        let page = AmityPollPostComposerPage(targetId: context.event.discussionCommunityId, targetType: .community, pollType: pollType, event: context.event)
        let vc = AmitySwiftUIHostingController(rootView: page)
        
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        navController.navigationBar.isHidden = true
        
        context.page.host.controller?.present(navController, animated: true)
    }
    
    open func goToEventAttendeesPage(context: AmityEventDetailPageBehavior.Context) {
        let view = AmityEventAttendeesPage(eventId: context.event.eventId)
        let controller = AmitySwiftUIHostingController(rootView: view)
        
        context.page.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
    
    open func goToUserProfilePage(context: AmityEventDetailPageBehavior.Context) {
        guard let userId = context.event.creator?.userId else { return }
        let userProfilePage = AmityUserProfilePage(userId: userId)
        let controller = AmitySwiftUIHostingController(rootView: userProfilePage)
        
        context.page.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
    
    open func goToCommunityProfilePage(context: AmityEventDetailPageBehavior.Context) {
        guard let communityId = context.event.targetCommunity?.communityId else { return }
        let page = AmityCommunityProfilePage(communityId: communityId)
        let hostController = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(hostController, animated: true)
    }
}
