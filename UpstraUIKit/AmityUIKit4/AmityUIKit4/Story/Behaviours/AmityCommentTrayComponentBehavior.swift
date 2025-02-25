//
//  AmityCommentTrayComponentBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/3/24.
//

import Foundation
import UIKit

open class AmityCommentTrayComponentBehavior {
    
    open class Context {
        public let component: AmityCommentTrayComponent
        public let userId: String
        
        init(component: AmityCommentTrayComponent, userId: String) {
            self.component = component
            self.userId = userId
        }
    }
    
    public init() {}
    
    open func goToUserProfilePage(context: AmityCommentTrayComponentBehavior.Context) {
        let page = AmityUserProfilePage(userId: context.userId)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.component.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
}
