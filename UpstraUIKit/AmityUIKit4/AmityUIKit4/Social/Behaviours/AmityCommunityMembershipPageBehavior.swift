//
//  AmityCommunityMembershipPageBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/12/24.
//

import Foundation
import UIKit
import AmitySDK

open class AmityCommunityMembershipPageBehavior {
    open class Context {
        public let page: AmityCommunityMembershipPage
        public var addUserPageCompletion: (([AmityUserModel]) -> Void)?
        
        
        public init(page: AmityCommunityMembershipPage, addUserPageCompletion: (([AmityUserModel]) -> Void)? = nil) {
            self.page = page
            self.addUserPageCompletion = addUserPageCompletion
        }
    }
    
    public init() {}
    
    
    open func goToAddMemberPage(_ context: AmityCommunityMembershipPageBehavior.Context) {
        let page = AmityCommunityAddUserPage(users: [], onAddedAction: context.addUserPageCompletion ?? {_ in })
        let vc = AmitySwiftUIHostingController(rootView: page)
        vc.modalPresentationStyle = .overFullScreen
        context.page.host.controller?.present(vc, animated: true)
    }
    
    open func goToUserProfilePage(_ context: AmityCommunityMembershipPageBehavior.Context) {
        // Left empty
    }
}

