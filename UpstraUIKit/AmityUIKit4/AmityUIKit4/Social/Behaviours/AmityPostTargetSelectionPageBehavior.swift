//
//  AmityPostTargetSelectionPageBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 7/9/24.
//

import Foundation
import AmitySDK

open class AmityPostTargetSelectionPageBehavior {
    
    open class Context {
        public let page: AmityPostTargetSelectionPage
        public let community: AmityCommunityModel?
        
        init(page: AmityPostTargetSelectionPage, community: AmityCommunityModel?) {
            self.page = page
            self.community = community
        }
    }
    
    public init() {}
    
    open func goToPostComposerPage(context: AmityPostTargetSelectionPageBehavior.Context) {
        let createOptions: AmityPostComposerOptions
        
        if let community = context.community {
            createOptions = AmityPostComposerOptions.createOptions(targetId: community.communityId, targetType: .community, community: community)
        } else {
            createOptions = AmityPostComposerOptions.createOptions(targetId: nil, targetType: .user, community: nil)
        }
        
        let view = AmityPostComposerPage(options: createOptions)
        let controller = AmitySwiftUIHostingController(rootView: view)
        context.page.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
    
    open func goToClipComposerPage(context: AmityPostTargetSelectionPageBehavior.Context) {
        
        var targetId: String = AmityUIKitManagerInternal.shared.currentUserId
        var targetType: AmityPostTargetType = .user
        
        if let community = context.community {
            targetId = community.communityId
            targetType = .community
        }
        
        let view = AmityCreateClipPostPage(targetId: targetId, targetType: targetType, community: context.community)
        let controller = AmitySwiftUIHostingController(rootView: view)
        context.page.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
}
