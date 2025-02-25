//
//  AmityCommunitySetupPageBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/15/24.
//

import Foundation
import UIKit

open class AmityCommunitySetupPageBehavior {
    open class Context {
        public let page: AmityCommunitySetupPage
        public let selectedCategories: [AmityCommunityCategoryModel]
        public let onCategoryAddedAction: (([AmityCommunityCategoryModel]) -> Void)?
        public let selectedUsers: [AmityUserModel]
        public let onUserAddedAction: (([AmityUserModel]) -> Void)?
        
        init(page: AmityCommunitySetupPage, 
             selectedCategories: [AmityCommunityCategoryModel] = [],
             onCategoryAddedAction: (([AmityCommunityCategoryModel]) -> Void)? = nil,
             selectedUsers: [AmityUserModel] = [],
             onUserAddedAction: (([AmityUserModel]) -> Void)? = nil) {
            self.page = page
            self.selectedCategories = selectedCategories
            self.onCategoryAddedAction = onCategoryAddedAction
            self.selectedUsers = selectedUsers
            self.onUserAddedAction = onUserAddedAction
        }
    }
    
    public init() {}
    
    open func goToAddCategoryPage(_ context: AmityCommunitySetupPageBehavior.Context) {
        let view = AmityCommunityAddCategoryPage(categories: context.selectedCategories, onAddedAction: context.onCategoryAddedAction ?? { _ in })
        let vc = AmitySwiftUIHostingController(rootView: view)
        vc.modalPresentationStyle = .overFullScreen
        context.page.host.controller?.present(vc, animated: true)
    }
    
    open func goToAddMemberPage(_ context: AmityCommunitySetupPageBehavior.Context) {
        let view = AmityCommunityAddUserPage(users: context.selectedUsers, onAddedAction: context.onUserAddedAction ?? { _ in })
        let vc = AmitySwiftUIHostingController(rootView: view)
        vc.modalPresentationStyle = .overFullScreen
        context.page.host.controller?.present(vc, animated: true)
    }
}
