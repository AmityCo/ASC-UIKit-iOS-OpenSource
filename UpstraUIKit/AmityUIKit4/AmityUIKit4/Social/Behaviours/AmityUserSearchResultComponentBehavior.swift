//
//  AmityUserSearchResultComponentBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 7/10/24.
//

import Foundation
import AmitySDK

open class AmityUserSearchResultComponentBehavior {
    
    open class Context {
        public let component: AmityUserSearchResultComponent
        public let user: AmityUser
        
        init(component: AmityUserSearchResultComponent, user: AmityUser) {
            self.component = component
            self.user = user
        }
    }
    
    public init() {}
    
    open func goToUserProfilePage(context: AmityUserSearchResultComponentBehavior.Context) {
        let userProfilePage = AmityUserProfilePage(userId: context.user.userId)
        let controller = AmitySwiftUIHostingController(rootView: userProfilePage)
        context.component.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
    
}
