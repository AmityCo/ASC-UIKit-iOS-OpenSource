//
//  StoryTabComponentBehaviour.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/29/23.
//

import Foundation
import SwiftUI

class StoryTabComponentBehaviour {
    class Context {
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
    
    func goToCameraPage(context: StoryTabComponentBehaviour.Context) {
        let cameraPage = AmityCameraPage(targetId: context.storyCreationTargetId, avatar: context.storyCreationAvatar)

        let navigationController = UINavigationController(rootViewController: SwiftUIHostingController(rootView: cameraPage))
        navigationController.navigationBar.isHidden = true
        navigationController.modalPresentationStyle = .overFullScreen
        navigationController.modalTransitionStyle = .crossDissolve
        
        let sourceController = context.component.host.controller
        sourceController?.present(navigationController, animated: true)
    }
    
    func goToViewStoryPage(context: StoryTabComponentBehaviour.Context) {

        let storyPage = AmityStoryPage(storyTargets: context.storyTargets!)
        
        let navigationController = UINavigationController(rootViewController: SwiftUIHostingController(rootView: storyPage))
        navigationController.navigationBar.isHidden = true
        navigationController.modalPresentationStyle = .overFullScreen
        navigationController.modalTransitionStyle = .crossDissolve
        
        let sourceController = context.component.host.controller
        sourceController?.present(navigationController, animated: true)
        
    }
}
