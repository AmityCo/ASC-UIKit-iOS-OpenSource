//
//  AmitySocialV4Compatible.swift
//  AmityUIKit
//
//  Created by Manuchet Rungraksa on 5/7/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import Foundation
import AmitySDK
import UIKit
#if canImport(AmityUIKit4)
import AmityUIKit4
#endif

#if canImport(AmityUIKit4)
public class AmitySocialV4Compatible: AmityPageViewController {
    
    // MARK: - Properties
    public let newsFeedVC = AmityV4NewsFeedViewController.make()
    public let exploreVC = AmityCommunityExplorerViewController.make()
    public let myCommunityVC = AmityMyCommunityViewController.make()

    private init() {
        super.init(nibName: AmityCommunityHomePageViewController.identifier, bundle: AmityUIKitManager.bundle)
        title = AmityLocalizedStringSet.communityHomeTitle.localizedString
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar(moveToIndex: 0)
    }
    
    public static func make() -> AmitySocialV4Compatible {
        return AmitySocialV4Compatible()
    }
    
    override func moveToViewController(at index: Int, animated: Bool = true) {
        super.moveToViewController(at: index, animated: animated)
        setupNavigationBar(moveToIndex: index)
    }
    
    override func viewControllers(for pagerTabStripController: AmityPagerTabViewController) -> [UIViewController] {
        newsFeedVC.pageTitle = AmityLocalizedStringSet.newsfeedTitle.localizedString
        exploreVC.pageTitle = AmityLocalizedStringSet.exploreTitle.localizedString
        myCommunityVC.pageTitle = "My Communities"
        return [newsFeedVC, exploreVC, myCommunityVC]
    }
    
    // MARK: - Setup view
    
    private func setupNavigationBar(moveToIndex: Int) {
        
        var rightBarItems = [UIBarButtonItem]()
        
        if communityCreationButtonVisible(), moveToIndex == 2 {
            let createCommunityItem = UIBarButtonItem(image: AmityIconSet.iconAdd, style: .plain, target: self, action: #selector(createCommunityTap))
            createCommunityItem.tintColor = AmityColorSet.base
            navigationItem.rightBarButtonItem = createCommunityItem
            rightBarItems.append(createCommunityItem)
        }
        
        let searchItem = UIBarButtonItem(image: AmityIconSet.iconSearch, style: .plain, target: self, action: #selector(searchTap))
        searchItem.tintColor = AmityColorSet.base
        navigationItem.rightBarButtonItem = searchItem
        rightBarItems.append(searchItem)
        
        navigationItem.rightBarButtonItems = rightBarItems

    }
    
    @objc func createCommunityTap() {
        myCommunityVC.createCommunityTap()
    }
    
    private func communityCreationButtonVisible() -> Bool {
        // The default visibility of this button.
        var visible = true
        // If someone override this env, we then force visibility to be that value.
        if let overrideVisible = AmityUIKitManagerInternal.shared.env["amity_uikit_social_community_creation_button_visible"] as? Bool {
            visible = overrideVisible
        }
        return visible
    }
}

// MARK: - Action
private extension AmitySocialV4Compatible {
    @objc func searchTap() {
        let searchVC = AmitySearchViewController.make()
        let nav = UINavigationController(rootViewController: searchVC)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true, completion: nil)
    }
}


public class AmityV4NewsFeedViewController: AmityViewController, IndicatorInfoProvider {
    
    var pageTitle: String?
    
    var isEmpty: Bool = false

    func indicatorInfo(for pagerTabStripController: AmityPagerTabViewController) -> IndicatorInfo {
        return IndicatorInfo(title: pageTitle)
    }

    var newsFeedComponent: AmityNewsFeedComponent!
    var emptyNewsFeedComponent: AmityEmptyNewsFeedComponent!
    
    private let createPostButton: AmityFloatingButton = AmityFloatingButton()

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        newsFeedComponent = AmityNewsFeedComponent(pageId: .socialHomePage)
        let hostController = AmitySwiftUIHostingController(rootView: newsFeedComponent)
        
        addChild(hostController)
        hostController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostController.view)
        
        NSLayoutConstraint.activate([
            hostController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                ])
        hostController.didMove(toParent: self)
        setupPostButton()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }

    private func setupPostButton() {
        // setup button
        createPostButton.add(to: view, position: .bottomRight)
        createPostButton.image = AmityIconSet.iconCreatePost
        createPostButton.actionHandler = { [weak self] _ in
            guard let strongSelf = self else { return }
            AmityEventHandler.shared.createPostBeingPrepared(from: strongSelf, postOption: [.post, .story])
        }
    }

    static func make() -> AmityV4NewsFeedViewController {
        let vc = AmityV4NewsFeedViewController(nibName: nil, bundle: nil)
        return vc
    }
}

#endif
