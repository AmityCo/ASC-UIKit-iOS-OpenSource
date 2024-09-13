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
        
        init(page: AmitySocialHomePage) {
            self.page = page
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
        let vc = AmitySwiftUIHostingController(rootView: page)
        vc.modalPresentationStyle = .overFullScreen
        context.page.host.controller?.present(vc, animated: false)
    }
    
//    open func goToCommunitySetupPage(context: AmitySocialHomePageBehavior.Context) {
//        let page = AmityCommunitySetupPage(mode: .create)
//        let vc = AmitySwiftUIHostingController(rootView: page)
//        vc.modalPresentationStyle = .overFullScreen
//        context.page.host.controller?.present(vc, animated: false)
//    }
}
