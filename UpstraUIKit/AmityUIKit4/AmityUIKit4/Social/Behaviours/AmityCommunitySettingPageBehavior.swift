//
//  AmityCommunitySettingPageBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/15/24.
//

import Foundation
import UIKit
import AmitySDK

open class AmityCommunitySettingPageBehavior {
    open class Context {
        public let page: AmityCommunitySettingPage
        public let community: AmityCommunity
        
        public init(page: AmityCommunitySettingPage, community: AmityCommunity) {
            self.page = page
            self.community = community
        }
    }
    
    public init() {}
    
    open func goToEditCommunityPage(_ context: AmityCommunitySettingPageBehavior.Context) {
        let page = AmityCommunitySetupPage(mode: .edit(context.community))
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc, animation: .presentation)
    }
    
    open func goToMembershipPage(_ context: AmityCommunitySettingPageBehavior.Context) {
        let page = AmityCommunityMembershipPage(community: context.community)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc)
    }
    
    open func goToNotificationPage(_ context: AmityCommunitySettingPageBehavior.Context) {
        let page = AmityCommunityNotificationSettingPage(community: context.community)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc)
    }
    
    open func goToPostPermissionPage(_ context: AmityCommunitySettingPageBehavior.Context) {
        let page = AmityCommunityPostPermissionPage(community: context.community)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc)
    }
    
    open func goToStorySettingPage(_ context: AmityCommunitySettingPageBehavior.Context) {
        let page = AmityCommunityStorySettingPage(community: context.community)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc)
    }
}
