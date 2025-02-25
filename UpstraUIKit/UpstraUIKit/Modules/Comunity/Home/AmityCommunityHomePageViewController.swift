//
//  AmityCommunityHomePageViewController.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 18/8/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit

public class AmityCommunityHomePageViewController: AmityPageViewController {
    
    // MARK: - Properties
    public let newsFeedVC = AmityNewsfeedViewController.make()
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
    
    public static func make() -> AmityCommunityHomePageViewController {
        return AmityCommunityHomePageViewController()
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
private extension AmityCommunityHomePageViewController {
    @objc func searchTap() {
        let searchVC = AmitySearchViewController.make()
        let nav = UINavigationController(rootViewController: searchVC)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true, completion: nil)
    }
}

