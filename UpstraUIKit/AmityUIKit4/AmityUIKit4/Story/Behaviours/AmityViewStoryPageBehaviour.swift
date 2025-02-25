//
//  AmityViewStoryPageBehaviour.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/15/24.
//

import Foundation
import AmitySDK
import UIKit

open class AmityViewStoryPageBehaviour {
    
    open class Context {
        public let page: AmityViewStoryPage
        public let targetId: String
        public let targetType: AmityStoryTargetType
        
        init(page: AmityViewStoryPage, targetId: String, targetType: AmityStoryTargetType) {
            self.page = page
            self.targetId = targetId
            self.targetType = targetType
        }
    }
    
    public init() {}
    
    open func goToCommunityPage(context: Context) {
        let communityId = context.targetId
        
        let communityProfilePage = AmityCommunityProfilePage(communityId: communityId)
        let controller = AmitySwiftUIHostingController(rootView: communityProfilePage)
        controller.navigationController?.isNavigationBarHidden = true
        
        context.page.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
    
    open func goToCreateStoryPage(context: Context) {
        let createStoryPage = AmityCreateStoryPage(targetId: context.targetId, targetType: context.targetType)
        let controller = AmitySwiftUIHostingController(rootView: createStoryPage)
        
        context.page.host.controller?.navigationController?.setViewControllers([controller], animated: false)
    }
}
