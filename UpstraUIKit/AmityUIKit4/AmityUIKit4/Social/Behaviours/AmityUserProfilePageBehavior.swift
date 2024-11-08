//
//  AmityUserProfilePageBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/3/24.
//

import Foundation
import UIKit

open class AmityUserProfilePageBehavior {
    
    open class Context {
        public let page: AmityUserProfilePage
        
        init(page: AmityUserProfilePage) {
            self.page = page
        }
    }
    
    public init() {}
    
    open func goToEditUserPage(context: AmityUserProfilePageBehavior.Context) {
        let page = AmityEditUserProfilePage()
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
    open func goToBlockedUsersPage(context: AmityUserProfilePageBehavior.Context) {
        let page = AmityBlockedUsersPage()
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.page.host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
    open func goToPostComposerPage(context: AmityUserProfilePageBehavior.Context) {
        let options = AmityPostComposerOptions.createOptions(targetId: nil, targetType: .user, community: nil)
        let page = AmityPostComposerPage(options: options)
        let vc = AmitySwiftUIHostingController(rootView: page)
        
        let navigationController = UINavigationController(rootViewController: vc)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.navigationBar.isHidden = true
        
        context.page.host.controller?.present(navigationController, animated: true)
    }
    
    open func goToPollPostComposerPage(context: AmityUserProfilePageBehavior.Context) {
        let page = AmityPollPostComposerPage(targetId: nil, targetType: .user)
        let vc = AmitySwiftUIHostingController(rootView: page)
        
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        navController.navigationBar.isHidden = true
        
        context.page.host.controller?.present(navController, animated: true)
    }
}
