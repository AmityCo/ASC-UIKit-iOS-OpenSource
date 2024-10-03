//
//  AmityBlockedUsersPageBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/3/24.
//

import Foundation
import UIKit

open class AmityBlockedUsersPageBehavior {
    
    open class Context {
        public let page: AmityBlockedUsersPage
        public let userId: String
        
        init(page: AmityBlockedUsersPage, userId: String) {
            self.page = page
            self.userId = userId
        }
    }
    
    public init() {}
    
    open func goToUserProfilePage(context: AmityBlockedUsersPageBehavior.Context) {
        let page = AmityUserProfilePage(userId: context.userId)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
}

