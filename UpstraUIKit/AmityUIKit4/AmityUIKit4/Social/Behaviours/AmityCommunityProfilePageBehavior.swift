//
//  AmityCommunityProfilePageBehavior.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 12/7/2567 BE.
//

import Foundation
import UIKit
import AmitySDK

open class AmityCommunityProfilePageBehavior {
    
    open class Context {
        public let page: AmityCommunityProfilePage
        public var community: AmityCommunity?
        public let showPollResult: Bool
        
        init(page: AmityCommunityProfilePage, community: AmityCommunity? = nil, showPollResult: Bool = false) {
            self.page = page
            self.community = community
            self.showPollResult = showPollResult
        }
    }
    
    public init() {}
    
    open func goToPendingPostPage(context: AmityCommunityProfilePageBehavior.Context) {
        guard let community = context.community else { return }
        let page = AmityPendingPostsPage(community: community)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
    open func goToCommunitySettingPage(context: AmityCommunityProfilePageBehavior.Context) {
        guard let community = context.community else { return }
        let page = AmityCommunitySettingPage(community: community)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
    open func goToPostComposerPage(context: AmityCommunityProfilePageBehavior.Context, community: AmityCommunityModel? = nil) {
        
        if let community = community {
            let createOptions: AmityPostComposerOptions

            createOptions = AmityPostComposerOptions.createOptions(targetId: community.communityId, targetType: .community, community: community)
            
            let view = AmityPostComposerPage(options: createOptions)
            let controller = AmitySwiftUIHostingController(rootView: view)
            
            let navigationController = UINavigationController(rootViewController: controller)
            navigationController.modalPresentationStyle = .fullScreen
            navigationController.navigationBar.isHidden = true
            
            context.page.host.controller?.present(navigationController, animated: true)
        }
    }
    
    open func goToPollPostComposerPage(context: AmityCommunityProfilePageBehavior.Context, community: AmityCommunityModel?) {
        
        if let community = community {
            let page = AmityPollPostComposerPage(targetId: community.communityId, targetType: .community)
            let vc = AmitySwiftUIHostingController(rootView: page)
            
            let navController = UINavigationController(rootViewController: vc)
            navController.modalPresentationStyle = .fullScreen
            navController.navigationBar.isHidden = true
            
            context.page.host.controller?.present(navController, animated: true)
        }
    }
    
    open func goToLivestreamPostComposerPage(context: AmityCommunityProfilePageBehavior.Context, community: AmityCommunityModel?) {
        
        if let community = community {
            let page = AmityCreateLivestreamPage(targetId: community.communityId, targetType: .community)
            let vc = AmitySwiftUIHostingController(rootView: page)
            
            let navController = UINavigationController(rootViewController: vc)
            navController.modalPresentationStyle = .fullScreen
            navController.navigationBar.isHidden = true
            
            context.page.host.controller?.present(navController, animated: true)
        }
    }
    
    open func goToCreateStoryPage(context: AmityCommunityProfilePageBehavior.Context, community: AmityCommunityModel?) {
        
        if let community = community {
            
            let createStoryPage = AmityCreateStoryPage(targetId: community.communityId, targetType: .community)

            let controller = AmitySwiftUIHostingController(rootView: createStoryPage)
            
            let navigationController = UINavigationController(rootViewController: controller)
            navigationController.modalPresentationStyle = .fullScreen
            navigationController.navigationBar.isHidden = true
            
            context.page.host.controller?.present(navigationController, animated: true)
            
        }
        
    }
    
    open func goToMemberListPage(context: AmityCommunityProfilePageBehavior.Context, community: AmityCommunityModel?) {
        if let community = community {
            let page = AmityCommunityMembershipPage(community: community.object)
            let controller = AmitySwiftUIHostingController(rootView: page)
            context.page.host.controller?.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    
    open func goToPostDetailPage(context: AmityCommunityProfilePageBehavior.Context, post: AmityPostModel?, category: AmityPostCategory = .general) {
        
        if let post = post {
            let postComponentContext = AmityPostContentComponent.Context(shouldShowPollResults: context.showPollResult, category: category, shouldHideTarget: true)
            let vc = AmitySwiftUIHostingController(rootView: AmityPostDetailPage(post: post.object, context: postComponentContext))
            let host = context.page.host
            host.controller?.navigationController?.pushViewController(vc, animated: true)            
        }
    }
    
}
