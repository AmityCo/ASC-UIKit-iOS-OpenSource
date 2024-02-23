//
//  AmityViewStoryPageBehaviour.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/15/24.
//

import Foundation
import AmitySDK

open class AmityViewStoryPageBehaviour {
    
    open class Context {
        public let page: AmityViewStoryPage
        public let community: AmityCommunity
        
        init(page: AmityViewStoryPage, community: AmityCommunity) {
            self.page = page
            self.community = community
        }
    }
    
    public init() {}
    
    open func goToCommunityPage(context: Context) {}
}
