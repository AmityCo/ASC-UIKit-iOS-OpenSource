//
//  AmityPostContentComponentBehavior.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 5/7/2567 BE.
//

import Foundation
import UIKit

open class AmityPostContentComponentBehavior {
    
    open class Context {
        public let component: AmityPostContentComponent
        public let userId: String?
        public let searchKeyword: String?
        
        init(component: AmityPostContentComponent, userId: String? = nil, searchKeyword: String? = nil) {
            self.component = component
            self.userId = userId
            self.searchKeyword = searchKeyword
        }
    }
    
    public init() {}
    
    open func goToCommunityProfilePage(context: AmityPostContentComponentBehavior.Context) {
        guard let communityId = context.component.post.targetCommunity?.communityId else { return }
        
        let communityProfilePage = AmityCommunityProfilePage(communityId: communityId)
        let controller = AmitySwiftUIHostingController(rootView: communityProfilePage)
        context.component.host.controller?.navigationController?.isNavigationBarHidden = true
        context.component.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
    
    open func goToUserProfilePage(context: AmityPostContentComponentBehavior.Context) {
        let userProfilePage = AmityUserProfilePage(userId: context.userId ?? context.component.post.postedUserId)
        let controller = AmitySwiftUIHostingController(rootView: userProfilePage)
        context.component.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
    
    open func goToPostComposerPage(context: AmityPostContentComponentBehavior.Context) {

    }
    
    open func goToSocialGlobalSearchPage(context: AmityPostContentComponentBehavior.Context) {
        let searchPage = AmitySocialGlobalSearchPage(searchKeyword: context.searchKeyword)
        let controller = AmitySwiftUIHostingController(rootView: searchPage)
        context.component.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
}

