//
//  AmitySocialHomePageBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 7/9/24.
//

import Foundation
import UIKit

open class AmitySocialHomePageBehavior {
    
    open class Context {
        public let page: AmitySocialHomePage
        let clipFeedAction: ((ClipFeedAction) -> Void)?
        
        init(page: AmitySocialHomePage, clipFeedAction: ((ClipFeedAction) -> Void)? = nil) {
            self.page = page
            self.clipFeedAction = clipFeedAction
        }
    }
    
    public init() {}
    
    open func goToGlobalSearchPage(context: AmitySocialHomePageBehavior.Context) {
        let page = AmitySocialGlobalSearchPage()
        let vc = AmitySwiftUIHostingNavigationController(rootView: page)
        vc.isNavigationBarHidden = true
        vc.modalPresentationStyle = .overFullScreen
        context.page.host.controller?.present(vc, animated: false)
    }
    
    open func goToMyCommunitiesSearchPage(context: AmitySocialHomePageBehavior.Context) {
        let page = AmityMyCommunitiesSearchPage()
        let vc = AmitySwiftUIHostingNavigationController(rootView: page)
        vc.isNavigationBarHidden = true
        vc.modalPresentationStyle = .overFullScreen
        context.page.host.controller?.present(vc, animated: false)
    }
    
    open func goToNotificationTrayPage(context: AmitySocialHomePageBehavior.Context) {
        let page = AmityNotificationTrayPage()
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
    open func goToClipFeedPage(context: AmitySocialHomePageBehavior.Context) {
        let page = AmityClipFeedPage(provider: GlobalFeedClipService(), onTapAction: context.clipFeedAction)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
}
