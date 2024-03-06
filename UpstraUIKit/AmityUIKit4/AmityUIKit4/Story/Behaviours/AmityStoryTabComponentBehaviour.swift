//
//  StoryTabComponentBehaviour.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/29/23.
//

import Foundation
import SwiftUI

open class AmityStoryTabComponentBehaviour {
    open class Context {
        public let component: AmityStoryTabComponent
        public let storyTargets: [AmityStoryTargetModel]
        public let storyCreationTargetId: String
        public let storyCreationAvatar: URL?
        public let startFromTargetIndex: Int
        
        init(component: AmityStoryTabComponent, storyTargets: [AmityStoryTargetModel], storyCreationTargetId: String, storyCreationAvatar: URL?, startFromTargetIndex: Int) {
            self.component = component
            self.storyTargets = storyTargets
            self.storyCreationTargetId = storyCreationTargetId
            self.storyCreationAvatar = storyCreationAvatar
            self.startFromTargetIndex = startFromTargetIndex
        }
    }
    
    public init() {}
    
    open func goToCreateStoryPage(context: AmityStoryTabComponentBehaviour.Context) {
        let createStoryPage = AmityCreateStoryPage(targetId: context.storyCreationTargetId, avatar: context.storyCreationAvatar)

        let navigationController = UINavigationController(rootViewController: SwiftUIHostingController(rootView: createStoryPage))
        navigationController.navigationBar.isHidden = true
        navigationController.modalPresentationStyle = .overFullScreen
        navigationController.modalTransitionStyle = .crossDissolve
        
        let sourceController = context.component.host.controller
        sourceController?.present(navigationController, animated: true)
    }
    
    open func goToViewStoryPage(context: AmityStoryTabComponentBehaviour.Context) {

        let viewStoryPage = AmityViewStoryPage(storyTargets: context.storyTargets, startFromTargetIndex: context.startFromTargetIndex)
        
        let navigationController = UINavigationController(rootViewController: SwiftUIHostingController(rootView: viewStoryPage))
        navigationController.navigationBar.isHidden = true
        navigationController.modalPresentationStyle = .overFullScreen
        
        let sourceController = context.component.host.controller
        sourceController?.present(navigationController, animated: true)
        
    }
}
