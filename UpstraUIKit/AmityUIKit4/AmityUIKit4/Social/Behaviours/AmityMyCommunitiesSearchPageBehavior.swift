//
//  AmityMyCommunitiesSearchPageBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 7/9/24.
//

import Foundation

open class AmityMyCommunitiesSearchPageBehavior {
    
    open class Context {
        public let page: AmityMyCommunitiesSearchPage
        public let communityId: String?
        
        init(page: AmityMyCommunitiesSearchPage, communityId: String? = nil) {
            self.page = page
            self.communityId = communityId
        }
    }
    
    public init() {}
    
    open func goToCommunityProfilePage(context: AmityMyCommunitiesSearchPageBehavior.Context) {
        
        guard let communityId = context.communityId else { return }
        
        let communityProfilePage = AmityCommunityProfilePage(communityId: communityId)
        let controller = AmitySwiftUIHostingController(rootView: communityProfilePage)
        controller.navigationController?.isNavigationBarHidden = true
        
        context.page.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
}
