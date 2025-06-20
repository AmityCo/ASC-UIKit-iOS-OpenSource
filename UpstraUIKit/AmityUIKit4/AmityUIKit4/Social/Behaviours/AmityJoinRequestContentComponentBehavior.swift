//
//  AmityJoinRequestContentComponentBehavior.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 5/6/25.
//

import SwiftUI
import UIKit

open class AmityJoinRequestContentComponentBehavior {
    
    open class Context {
        public let component: AmityJoinRequestContentComponent
        public let userId: String
        
        init(component: AmityJoinRequestContentComponent, userId: String) {
            self.component = component
            self.userId = userId
        }
    }
    
    public init() {}
    
    open func goTouserProfilePage(context: AmityJoinRequestContentComponentBehavior.Context) {
        let page = AmityUserProfilePage(userId: context.userId)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.component.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
}
