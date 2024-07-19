//
//  AmityCommunityProfilePageBehavior.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 12/7/2567 BE.
//

import Foundation
import UIKit

open class AmityCommunityProfilePageBehavior {
    
    open class Context {
        public let page: AmityCommunityProfilePage
        
        init(page: AmityCommunityProfilePage) {
            self.page = page
        }
    }
    
    public init() {}
    
    open func goToPendingPostPage(context: AmityCommunityProfilePageBehavior.Context) {
        
    }
    
    open func goToCommunitySettingPage(context: AmityCommunityProfilePageBehavior.Context) {

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
            
            let createStoryPage = AmityCreateStoryPage(targetId: community.communityId, targetType: .community)

            let controller = AmitySwiftUIHostingController(rootView: createStoryPage)
            
            let navigationController = UINavigationController(rootViewController: controller)
            navigationController.modalPresentationStyle = .fullScreen
            navigationController.navigationBar.isHidden = true
            
            context.page.host.controller?.present(navigationController, animated: true)
            
        }
        
    }
    
    
    open func goToPostDetailPage(context: AmityCommunityProfilePageBehavior.Context, post: AmityPostModel?, category: AmityPostCategory = .general) {
        
        if let post = post {
            
            let vc = AmitySwiftUIHostingController(rootView: AmityPostDetailPage(post: post.object, category: category, hideTarget: true))
            let host = context.page.host
            host.controller?.navigationController?.pushViewController(vc, animated: true)            
            
        }
        
    }
    
}
