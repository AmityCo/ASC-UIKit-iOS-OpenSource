//
//  StoryTabComponentBehaviour.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/29/23.
//

import Foundation
import SwiftUI

open class AmityStoryTabComponentBehaviour {
    public class Context {
        let component: AmityStoryTabComponent
        let storyTargets: [StoryTarget]?
        let storyCreationTargetId: String
        let storyCreationAvatar: UIImage?
        
        init(component: AmityStoryTabComponent, storyTargets: [StoryTarget]?, storyCreationTargetId: String, storyCreationAvatar: UIImage?) {
            self.component = component
            self.storyTargets = storyTargets
            self.storyCreationTargetId = storyCreationTargetId
            self.storyCreationAvatar = storyCreationAvatar
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

        let viewStoryPage = AmityViewStoryPage(storyTargets: context.storyTargets!)
        
        let navigationController = UINavigationController(rootViewController: SwiftUIHostingController(rootView: viewStoryPage))
        navigationController.navigationBar.isHidden = true
        navigationController.modalPresentationStyle = .overFullScreen
        navigationController.modalTransitionStyle = .crossDissolve
        
        let sourceController = context.component.host.controller
        sourceController?.present(navigationController, animated: true)
        
    }
}
