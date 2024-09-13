//
//  AmityCommunityNotificationSettingPageBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/9/24.
//

import Foundation
import UIKit
import AmitySDK

open class AmityCommunityNotificationSettingPageBehavior {
    open class Context {
        public let page: AmityCommunityNotificationSettingPage
        public let community: AmityCommunity
        
        public init(page: AmityCommunityNotificationSettingPage, community: AmityCommunity) {
            self.page = page
            self.community = community
        }
    }
    
    public init() {}
    
    open func goToPostsNotificationSettingPage(_ context: AmityCommunityNotificationSettingPageBehavior.Context) {
        let page = AmityCommunityPostsNotificationSettingPage(community: context.community)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc)
    }
    
    
    open func goToCommentsNotificationSettingPage(_ context: AmityCommunityNotificationSettingPageBehavior.Context) {
        let page = AmityCommunityCommentsNotificationSettingPage(community: context.community)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc)
    }
    
    open func goToStoriesNotificationSettingPage(_ context: AmityCommunityNotificationSettingPageBehavior.Context) {
        let page = AmityCommunityStoriesNotificationSettingPage(community: context.community)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc)
    }
}

