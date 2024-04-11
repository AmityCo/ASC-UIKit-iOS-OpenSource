//
//  AmityTargetSelectionPageBehaviour.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 4/2/24.
//

import Foundation
import AmitySDK

open class AmityTargetSelectionPageBehaviour {
    
    open class Context {
        public let page: AmityTargetSelectionPage
        public let community: AmityCommunity
        public let targetType: AmityStoryTargetType
        
        init(page: AmityTargetSelectionPage, community: AmityCommunity, targetType: AmityStoryTargetType) {
            self.page = page
            self.community = community
            self.targetType = targetType
        }
    }
    
    public init() {}
    
    open func selectTargetAction(context: Context) {
        let createStoryPage = AmityCreateStoryPage(targetId: context.community.communityId, targetType: context.targetType)
        let controller = AmitySwiftUIHostingController(rootView: createStoryPage)
        
        context.page.host.controller?.navigationController?.setViewControllers([controller], animated: false)
    }
}
