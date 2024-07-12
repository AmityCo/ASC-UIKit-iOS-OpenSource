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
        
        init(component: AmityPostContentComponent) {
            self.component = component
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

    }
    
    open func goToPostComposerPage(context: AmityPostContentComponentBehavior.Context) {

    }
    
}

