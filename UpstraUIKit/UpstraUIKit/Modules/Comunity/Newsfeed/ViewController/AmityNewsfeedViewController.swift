//
//  AmityNewsfeedViewController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 24/8/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import AmitySDK
import Combine

/// A view controller for providing global feed with create post functionality.
public class AmityNewsfeedViewController: AmityViewController, IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: AmityPagerTabViewController) -> IndicatorInfo {
        return IndicatorInfo(title: pageTitle)
    }
    
    // MARK: - Properties
    var pageTitle: String?
    
    private let emptyView = AmityNewsfeedEmptyView()
    private var headerView = AmityStoryTabViewController.make()
    private let createPostButton: AmityFloatingButton = AmityFloatingButton()
    private let feedViewController = AmityFeedViewController.make(feedType: .globalFeed)
    
    private let storyRepository = AmityStoryRepository(client: AmityUIKitManagerInternal.shared.client)
    private var storyGlobalFeedCollection: AmityCollection<AmityStoryTarget>?
    private var cancellable: AnyCancellable?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupFeedView()
        setupEmptyView()
        setupHeaderView()
        setupPostButton()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        headerView.retrieveCommunityList()
    }
    
    public static func make() -> AmityNewsfeedViewController {
        let vc = AmityNewsfeedViewController(nibName: nil, bundle: nil)
        return vc
    }
}

// MARK: - Setup view
private extension AmityNewsfeedViewController {
    
    private func setupFeedView() {
        addChild(viewController: feedViewController)
        feedViewController.dataDidUpdateHandler = { [weak self] itemCount in
            self?.emptyView.setNeedsUpdateState()
        }
        
        feedViewController.pullRefreshHandler = { [weak self] in
//            self?.headerView.retrieveCommunityList()
            self?.getGlobalStoryTargets()
        }
    }
    
    private func setupHeaderView() {
//        headerView.delegate = self
        storyGlobalFeedCollection = getGlobalStoryTargets()
        cancellable = nil
        cancellable = storyGlobalFeedCollection?.$snapshots
            .sink(receiveValue: { [weak self] targets in
                self?.feedViewController.headerView = targets.count == 0 ? nil : self?.headerView
            })
    }
    
    private func setupEmptyView() {
        emptyView.exploreHandler = { [weak self] in
            guard let parent = self?.parent as? AmityCommunityHomePageViewController else { return }
            // Switch to explore tap which is an index 1.
            parent.setCurrentIndex(1)
        }
        emptyView.createHandler = { [weak self] in
            let vc = AmityCommunityCreatorViewController.make()
            vc.delegate = self
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .overFullScreen
            self?.present(nav, animated: true, completion: nil)
        }
        feedViewController.emptyView = emptyView

    }
    
    private func setupPostButton() {
        // setup button
        createPostButton.add(to: view, position: .bottomRight)
        createPostButton.image = AmityIconSet.iconCreatePost
        createPostButton.actionHandler = { [weak self] _ in
            guard let strongSelf = self else { return }
            AmityEventHandler.shared.createPostBeingPrepared(from: strongSelf)
        }
    }
    
    @discardableResult
    private func getGlobalStoryTargets() -> AmityCollection<AmityStoryTarget> {
        storyRepository.getGlobalStoryTargets(option: .smart)
    }
}

extension AmityNewsfeedViewController: AmityCommunityProfileEditorViewControllerDelegate {
    
    public func viewController(_ viewController: AmityCommunityProfileEditorViewController, didFinishCreateCommunity communityId: String) {
        AmityEventHandler.shared.communityDidTap(from: self, communityId: communityId)
    }
    
}

//extension AmityNewsfeedViewController: AmityMyCommunityPreviewViewControllerDelegate {
//
//    public func viewController(_ viewController: AmityMyCommunityPreviewViewController, didPerformAction action: AmityMyCommunityPreviewViewController.ActionType) {
//        switch action {
//        case .seeAll:
//            let vc = AmityMyCommunityViewController.make()
//            navigationController?.pushViewController(vc, animated: true)
//        case .communityItem(let communityId):
//            AmityEventHandler.shared.communityDidTap(from: self, communityId: communityId)
//        }
//    }
//
//    public func viewController(_ viewController: AmityMyCommunityPreviewViewController, shouldShowMyCommunityPreview: Bool) {
//        if shouldShowMyCommunityPreview {
//            feedViewController.headerView = globalFeedView
//        } else {
//            feedViewController.headerView = globalFeedView
//        }
//    }
//}
