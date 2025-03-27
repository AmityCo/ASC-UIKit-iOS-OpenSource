//
//  AmityCreatePostMenuComponentBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 7/9/24.
//

import Foundation
import UIKit

open class AmityCreatePostMenuComponentBehavior {
    
    open class Context {
        public let component: AmityCreatePostMenuComponent
        
        init(component: AmityCreatePostMenuComponent) {
            self.component = component
        }
    }
    
    public init() {}
    
    open func goToSelectPostTargetPage(context: AmityCreatePostMenuComponentBehavior.Context) {
        let view = AmityPostTargetSelectionPage()
        let controller = AmitySwiftUIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.navigationBar.isHidden = true
        context.component.host.controller?.present(navigationController, animated: true)
    }
    
    open func goToSelectStoryTargetPage(context: AmityCreatePostMenuComponentBehavior.Context) {
        let view = AmityStoryTargetSelectionPage()
        let controller = AmitySwiftUIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.navigationBar.isHidden = true
        context.component.host.controller?.present(navigationController, animated: true)
    }
    
    open func goToSelectPollPostTargetPage(context: AmityCreatePostMenuComponentBehavior.Context) {
        let view = AmityPollTargetSelectionPage()
        let controller = AmitySwiftUIHostingController(rootView: view)
        
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.navigationBar.isHidden = true
        context.component.host.controller?.present(navigationController, animated: true)
    }
    
    open func goToSelectLiveStreamPostTargetPage(context: AmityCreatePostMenuComponentBehavior.Context) {
        let view = AmityLivestreamPostTargetSelectionPage()
        let controller = AmitySwiftUIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.navigationBar.isHidden = true
        context.component.host.controller?.present(navigationController, animated: true)
    }
}
