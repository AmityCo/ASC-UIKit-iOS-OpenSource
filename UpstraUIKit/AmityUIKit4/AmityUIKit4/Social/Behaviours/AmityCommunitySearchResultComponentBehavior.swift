//
//  AmityCommunitySearchResultComponentBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 7/10/24.
//

import Foundation

open class AmityCommunitySearchResultComponentBehavior {
    
    open class Context {
        public let component: AmityCommunitySearchResultComponent
        let communityId: String?
        
        init(component: AmityCommunitySearchResultComponent, communityId: String? = nil) {
            self.component = component
            self.communityId = communityId
        }
    }
    
    public init() {}
    
    open func goToCommunityProfilePage(context: AmityCommunitySearchResultComponentBehavior.Context) {
        
        guard let communityId = context.communityId else { return }
        
        let communityProfilePage = AmityCommunityProfilePage(communityId: communityId)
        let controller = AmitySwiftUIHostingController(rootView: communityProfilePage)
        controller.navigationController?.isNavigationBarHidden = true

        context.component.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
    
}
