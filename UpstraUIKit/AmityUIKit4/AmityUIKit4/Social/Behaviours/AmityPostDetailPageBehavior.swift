//
//  AmityPostDetailPageBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 7/9/24.
//

import Foundation

open class AmityPostDetailPageBehavior {
    
    open class Context {
        public let page: AmityPostDetailPage
        public let userId: String
        
        init(page: AmityPostDetailPage, userId: String) {
            self.page = page
            self.userId = userId
        }
    }
    
    public init() {}
    
    open func goToUserProfilePage(context: AmityPostDetailPageBehavior.Context) {
        let page = AmityUserProfilePage(userId: context.userId)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
}
