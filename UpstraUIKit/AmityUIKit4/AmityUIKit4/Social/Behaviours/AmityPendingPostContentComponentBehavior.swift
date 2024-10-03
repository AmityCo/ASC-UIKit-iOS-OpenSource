//
//  AmityPendingPostContentComponentBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/3/24.
//

import Foundation
import UIKit

open class AmityPendingPostContentComponentBehavior {
    
    open class Context {
        public let component: AmityPendingPostContentComponent
        public let userId: String
        
        init(component: AmityPendingPostContentComponent, userId: String) {
            self.component = component
            self.userId = userId
        }
    }
    
    public init() {}
    
    open func goToUserProfilePage(context: AmityPendingPostContentComponentBehavior.Context) {
        let page = AmityUserProfilePage(userId: context.userId)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.component.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
}
