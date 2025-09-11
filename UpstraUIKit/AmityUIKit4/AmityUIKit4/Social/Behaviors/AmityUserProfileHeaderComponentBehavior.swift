//
//  AmityUserProfileHeaderComponentBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/3/24.
//

import Foundation
import UIKit

open class AmityUserProfileHeaderComponentBehavior {
    
    open class Context {
        public let component: AmityUserProfileHeaderComponent
        public let userId: String
        public let selectedTab: AmityUserRelationshipPageTab
        
        init(component: AmityUserProfileHeaderComponent, userId: String, selectedTab: AmityUserRelationshipPageTab = .following) {
            self.component = component
            self.userId = userId
            self.selectedTab = selectedTab
        }
    }
    
    public init() {}
    
    open func goToUserRelationshipPage(context: AmityUserProfileHeaderComponentBehavior.Context) {
        let page = AmityUserRelationshipPage(userId: context.userId, selectedTab: context.selectedTab)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.component.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
    open func goToPendingFollowRequestPage(context: AmityUserProfileHeaderComponentBehavior.Context) {
        let page = AmityUserPendingFollowRequestsPage()
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.component.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
}

