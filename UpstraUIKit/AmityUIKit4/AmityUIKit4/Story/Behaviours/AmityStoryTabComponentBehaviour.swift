//
//  StoryTabComponentBehaviour.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/29/23.
//

import Foundation
import SwiftUI
import AmitySDK

open class AmityStoryTabComponentBehaviour {
    open class Context {
        public let component: AmityStoryTabComponent
        public let storyFeedType: AmityStoryTabComponentType
        public let targetId: String
        public let targetType: AmityStoryTargetType
        
        init(component: AmityStoryTabComponent, storyFeedType: AmityStoryTabComponentType, targetId: String, targetType: AmityStoryTargetType) {
            self.component = component
            self.storyFeedType = storyFeedType
            self.targetId = targetId
            self.targetType = targetType
        }
    }
    
    public init() {}
    
    open func goToCreateStoryPage(context: AmityStoryTabComponentBehaviour.Context) {
        let createStoryPage = AmityCreateStoryPage(targetId: context.targetId, targetType: context.targetType)

        let navigationController = UINavigationController(rootViewController: AmitySwiftUIHostingController(rootView: createStoryPage))
        navigationController.navigationBar.isHidden = true
        navigationController.modalPresentationStyle = .overFullScreen
        navigationController.modalTransitionStyle = .crossDissolve
        
        let sourceController = context.component.host.controller
        sourceController?.present(navigationController, animated: true)
    }
    
    open func goToViewStoryPage(context: AmityStoryTabComponentBehaviour.Context) {
        let storyPageType: AmityViewStoryPageType
        
        switch context.storyFeedType {
        case .globalFeed:
            storyPageType = .globalFeed(context.targetId)
        case .communityFeed(let string):
            storyPageType = .communityFeed(context.targetId)
        }
        
        let viewStoryPage = AmityViewStoryPage(type: storyPageType)
        
        let navigationController = UINavigationController(rootViewController: AmitySwiftUIHostingController(rootView: viewStoryPage))
        navigationController.navigationBar.isHidden = true
        navigationController.modalPresentationStyle = .overFullScreen
        
        let sourceController = context.component.host.controller
        sourceController?.present(navigationController, animated: true)
        
    }
}
