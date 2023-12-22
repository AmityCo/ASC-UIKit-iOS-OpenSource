//
//  AmityStoryTabViewController.swift
//  AmityUIKit
//
//  Created by Zay Yar Htun on 12/1/23.
//  Copyright © 2023 Amity. All rights reserved.
//

import UIKit
#if canImport(AmityUIKit4)
import AmityUIKit4
#endif
import SwiftUI

// TEMP: This controller will be used for Global Feed in the future.
#if canImport(AmityUIKit4)
class AmityStoryTabViewController: AmityViewController {
    var storyTabComponent: AmityStoryTabComponent!
    var storyTabComponentViewModel: AmityStoryTabComponentViewModel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        storyTabComponentViewModel = AmityStoryTabComponentViewModel(storyTargets: [],
                                                                     hideStoryCreation: true, 
                                                                     creatorAvatar: UIImage(),
                                                                     isGlobalFeed: true,
                                                                     storyCreationTargetId: "")
        
        storyTabComponent = AmityStoryTabComponent(viewModel: storyTabComponentViewModel)
        let hostController = SwiftUIHostingController(rootView: storyTabComponent)
        
        addChild(hostController)
        hostController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostController.view)
        
        NSLayoutConstraint.activate([
            hostController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 10.0),
            hostController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 10.0),
                ])
        hostController.didMove(toParent: self)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }


    static func make() -> AmityStoryTabViewController {
        let vc = AmityStoryTabViewController(nibName: AmityStoryTabViewController.identifier, bundle: AmityUIKitManager.bundle)
        return vc
    }
    
    func updateStoryTargets(storyTargets: [StoryTarget]) {
        //storyTabComponent.viewModel.storyTargets = storyTargets
    }

}

extension AmityStoryTabViewController: FeedHeaderPresentable {
    public var headerView: UIView {
        return view
    }
    
    public var height: CGFloat {
        return 103
    }
}

#endif
