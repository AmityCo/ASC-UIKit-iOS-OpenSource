//
//  AmityMyCommunitiesComponentBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 7/9/24.
//

import Foundation

open class AmityMyCommunitiesComponentBehavior {
    
    open class Context {
        public let component: AmityMyCommunitiesComponent
        let communityId: String?
        
        init(component: AmityMyCommunitiesComponent, communityId: String? = nil) {
            self.component = component
            self.communityId = communityId
        }
    }
    
    public init() {}
    
    open func goToCommunityProfilePage(context: AmityMyCommunitiesComponentBehavior.Context) {
        
        guard let communityId = context.communityId else { return }
        
        let communityProfilePage = AmityCommunityProfilePage(communityId: communityId)
        let controller = AmitySwiftUIHostingController(rootView: communityProfilePage)
        controller.navigationController?.isNavigationBarHidden = true
        
        context.component.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
}
