//
//  AmityCommunityProfileHeaderViewController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 20/4/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK
import SwiftUI
#if canImport(AmityUIKit4)
import AmityUIKit4
#endif
import Combine


final class AmityCommunityProfileHeaderViewController: UIViewController {
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var avatarView: AmityImageView!
    @IBOutlet private var displayNameLabel: UILabel!
    @IBOutlet private var privateBadgeImageView: UIImageView!
    @IBOutlet private var officialBadgeImageView: UIImageView!
    @IBOutlet private var categoryLabel: UILabel!
    @IBOutlet private var postLabel: UILabel!
    @IBOutlet private var separatorView: UIView!
    @IBOutlet private var memberLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var actionButton: AmityButton!
    @IBOutlet private var actionStackView: UIStackView!
    
    @IBOutlet private var pendingPostsStatusView: UIView!
    @IBOutlet private var pendingPostsContainerView: UIView!
    @IBOutlet private var pendingPostsTitleLabel: UILabel!
    @IBOutlet private var pendingPostsDescriptionLabel: UILabel!
    
    @IBOutlet weak var storyTabView: UIView!
    
    // MARK: - Properties
    private var screenViewModel: AmityCommunityProfileScreenViewModelType!
    private weak var rootViewController: AmityCommunityProfilePageViewController?
    private let gradient = CAGradientLayer()
    private var channelToken: AmityNotificationToken?
    var isUpdateInProgress = false
    
    // MARK: - Callback
    var didUpdatePostBanner: (() -> Void)?
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDisplayName()
        setupBadgeView()
        setupSubTitleLabel()
        updatePostLabel(postCount: 0)
        updateMemberLabel(memberCount: 0)
        setupDescription()
        setupActionButton()
        setupPendingPosts()
    }
    
    static func make(rootViewController: AmityCommunityProfilePageViewController?, viewModel: AmityCommunityProfileScreenViewModelType) -> AmityCommunityProfileHeaderViewController {
        let vc = AmityCommunityProfileHeaderViewController(nibName: AmityCommunityProfileHeaderViewController.identifier, bundle: AmityUIKitManager.bundle)
        vc.rootViewController = rootViewController
        vc.screenViewModel = viewModel
        return vc
    }
    
    // MARK: - Setup views
    private func setupDisplayName() {
        avatarView.placeholder = AmityIconSet.defaultCommunity
        avatarView.contentMode = .scaleAspectFill
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.3).cgColor]
        gradient.locations = [0, 1]
        avatarView.layer.addSublayer(gradient)
        
        displayNameLabel.text = ""
        displayNameLabel.font = AmityFontSet.headerLine
        displayNameLabel.textColor = AmityColorSet.baseInverse
        displayNameLabel.numberOfLines = 0
        
        separatorView.backgroundColor = AmityColorSet.base.blend(.shade3)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = avatarView.frame
    }
    
    private func setupBadgeView() {
        privateBadgeImageView.image = AmityIconSet.iconPrivate
        privateBadgeImageView.tintColor = AmityColorSet.baseInverse
        privateBadgeImageView.isHidden = true
        privateBadgeImageView.image = AmityIconSet.iconPrivate
        officialBadgeImageView.image = AmityIconSet.iconBadgeCheckmark
        officialBadgeImageView.tintColor = AmityColorSet.baseInverse
        officialBadgeImageView.isHidden = true
    }
    
    private func setupSubTitleLabel() {
        categoryLabel.text = ""
        categoryLabel.font = AmityFontSet.body
        categoryLabel.textColor = AmityColorSet.baseInverse
        categoryLabel.numberOfLines = 1
    }
    
    private func updatePostLabel(postCount: Int) {
        var format = postCount == 1 ? AmityLocalizedStringSet.Unit.postSingular.localizedString : AmityLocalizedStringSet.Unit.postPlural.localizedString
        format = format.replacingOccurrences(of: " ", with: "\n") // adjust a format of localized string... "%@ posts" -> "%@\nposts"
        let value = postCount.formatUsingAbbrevation()
        let string = String.localizedStringWithFormat(format, value)
        
        let attribute = NSMutableAttributedString(string: string,
                                                  attributes: [.font : AmityFontSet.body,
                                                               .foregroundColor: AmityColorSet.base.blend(.shade1)])
        let range = NSString(string: string).range(of: value)
        attribute.addAttributes([.font : AmityFontSet.bodyBold,
                                 .foregroundColor: AmityColorSet.base], range: range)
        postLabel.attributedText = attribute
    }
    
    private func updateMemberLabel(memberCount: Int) {
        var  format = memberCount == 1 ? AmityLocalizedStringSet.Unit.memberSingular.localizedString : AmityLocalizedStringSet.Unit.memberPlural.localizedString
        format = format.replacingOccurrences(of: " ", with: "\n") // adjust a format of localized string... "%@ members" -> "%@\nmembers"
        let value = memberCount.formatUsingAbbrevation()
        let string = String.localizedStringWithFormat(format, value)
        
        let attribute = NSMutableAttributedString(string: string,
                                                  attributes: [.font : AmityFontSet.body,
                                                               .foregroundColor: AmityColorSet.base.blend(.shade1)])
        let range = NSString(string: string).range(of: value)
        attribute.addAttributes([.font : AmityFontSet.bodyBold,
                                 .foregroundColor: AmityColorSet.base], range: range)
        memberLabel.attributedText = attribute
    }
    
    private func setupDescription() {
        descriptionLabel.text = ""
        descriptionLabel.font = AmityFontSet.body
        descriptionLabel.textColor = AmityColorSet.base
        descriptionLabel.numberOfLines = 0
    }
    
    private func setupActionButton() {
        actionButton.isHidden = true
        actionButton.setTitleShadowColor(AmityColorSet.baseInverse, for: .normal)
        actionButton.setTitleFont(AmityFontSet.bodyBold)
        actionButton.addTarget(self, action: #selector(actionTap), for: .touchUpInside)
    }
    
    private func setupPendingPosts() {
        pendingPostsContainerView.isHidden = true
        pendingPostsContainerView.layer.cornerRadius = 4
        pendingPostsContainerView.backgroundColor = AmityColorSet.base.blend(.shade4)
        
        pendingPostsStatusView.backgroundColor = AmityColorSet.primary
        pendingPostsStatusView.layer.cornerRadius = pendingPostsStatusView.frame.height / 2
        
        pendingPostsTitleLabel.text = AmityLocalizedStringSet.PendingPosts.statusTitle.localizedString
        pendingPostsTitleLabel.font = AmityFontSet.bodyBold
        pendingPostsTitleLabel.textColor = AmityColorSet.base
        
        pendingPostsDescriptionLabel.font = AmityFontSet.caption
        pendingPostsDescriptionLabel.textColor = AmityColorSet.base.blend(.shade1)
    }
    
    
    // TEMP: AmityUIKit v4 integration in Old UIKit for Story Target
    // Need to refactor when global feed come in
    #if canImport(AmityUIKit4)
    var storyManager = StoryManager()
    var storyTabComponent: AmityStoryTabComponent!
    var storyCollection: AmityCollection<AmityStory>!
    var cancellable: AnyCancellable?
    var hasStoryManagePermission: Bool = false
    #endif
   
    
    private func setupStory(community: AmityCommunity) {
        #if canImport(AmityUIKit4)

        storyTabComponent = AmityStoryTabComponent(type: .communityFeed(community.communityId))
        
        let hostingController = AmitySwiftUIHostingController(rootView: storyTabComponent)
    
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.frame = storyTabView.frame
        storyTabView.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: storyTabView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: storyTabView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: storyTabView.topAnchor, constant: 3.0),
            hostingController.view.bottomAnchor.constraint(equalTo: storyTabView.bottomAnchor, constant: 3.0),
                ])
        hostingController.didMove(toParent: self)
        
        #endif
    }
    
    func updateStoryViewController(community: AmityCommunityModel) {
        #if canImport(AmityUIKit4)
        if storyTabView.subviews.isEmpty {
            setupStory(community: community.object)
        }
        storyCollection = storyManager.getActiveStories(in: community.communityId)
        
        Task {
            hasStoryManagePermission = await StoryPermissionChecker.checkUserHasManagePermission(communityId: community.communityId)
            self.cancellable = nil
            self.cancellable = self.storyCollection.$snapshots
                .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
                .sink { [weak self] stories in
                    Log.add("Story Count: \(stories.count)")
                    
                    if let hasPermission = self?.hasStoryManagePermission, hasPermission {
                        self?.storyTabView.isHidden = false
                    } else {
                        self?.storyTabView.isHidden = stories.count == 0
                    }
                }
        }
        
        #else
        storyTabView.isHidden = true
        #endif
    }
    
    
    // MARK: - Update views
    func updateView() {
        guard let community = screenViewModel.dataSource.community, !isUpdateInProgress else { return }
        isUpdateInProgress = true
        avatarView.setImage(withImageURL: community.avatarURL,
                            size: .large,
                            placeholder: AmityIconSet.defaultCommunity)
        displayNameLabel.text = community.displayName
        descriptionLabel.text = community.description
        descriptionLabel.isHidden = community.description == ""
        updateMemberLabel(memberCount: Int(community.membersCount))
        categoryLabel.text = community.category
        privateBadgeImageView.isHidden = community.isPublic
        officialBadgeImageView.isHidden = !community.isOfficial
        updateActionButton()
        shouldShowPendingsPostBanner()
        
        updateStoryViewController(community: community)
    }
    
    func updatePostsCount() {
        updatePostLabel(postCount: screenViewModel.dataSource.postCount)
    }
    
    private func updateActionButton() {
        switch screenViewModel.dataSource.memberStatusCommunity {
        case .guest:
            actionButton.setTitle(AmityLocalizedStringSet.communityDetailJoinButton.localizedString, for: .normal)
            actionButton.setImage(AmityIconSet.iconAdd, position: .left)
            actionButton.tintColor = AmityColorSet.baseInverse
            actionButton.backgroundColor = AmityColorSet.primary
            actionButton.layer.cornerRadius = 4
            actionButton.tag = 0
            actionButton.isHidden = false
        case .member:
            actionButton.setTitle(AmityLocalizedStringSet.communityDetailMessageButton.localizedString, for: .normal)
            actionButton.setImage(AmityIconSet.iconChat, position: .left)
            actionButton.tintColor = AmityColorSet.secondary
            actionButton.backgroundColor = AmityColorSet.backgroundColor
            actionButton.layer.borderColor = AmityColorSet.secondary.blend(.shade3).cgColor
            actionButton.layer.borderWidth = 1
            actionButton.layer.cornerRadius = 4
            actionButton.tag = 1
            actionButton.isHidden = true
        case .admin:
            actionButton.setTitle(AmityLocalizedStringSet.communityDetailEditProfileButton.localizedString, for: .normal)
            actionButton.setImage(AmityIconSet.iconEdit, position: .left)
            actionButton.tintColor = AmityColorSet.secondary
            actionButton.backgroundColor = AmityColorSet.backgroundColor
            actionButton.layer.borderColor = AmityColorSet.secondary.blend(.shade3).cgColor
            actionButton.layer.borderWidth = 1
            actionButton.layer.cornerRadius = 4
            actionButton.tag = 2
            actionButton.isHidden = false
        }
        actionStackView.isHidden = actionButton.isHidden
    }
    
    
    private func shouldShowPendingsPostBanner() {
        switch screenViewModel.dataSource.memberStatusCommunity {
        case .guest:
            pendingPostsContainerView.isHidden = true
            self.isUpdateInProgress = false
        case .member:
            screenViewModel.action.getPendingPostCount { [weak self] pendingPostsCount in
                self?.pendingPostsContainerView.isHidden = pendingPostsCount == 0
                self?.pendingPostsDescriptionLabel.text = AmityLocalizedStringSet.PendingPosts.statusMemberDesc.localizedString
                self?.didUpdatePostBanner?()
                self?.isUpdateInProgress = false
            }
        case .admin:
            screenViewModel.action.getPendingPostCount { [weak self] pendingPostsCount in
                self?.pendingPostsContainerView.isHidden = pendingPostsCount == 0
                self?.pendingPostsDescriptionLabel.text = String.localizedStringWithFormat(AmityLocalizedStringSet.PendingPosts.statusAdminDesc.localizedString, pendingPostsCount)
                self?.didUpdatePostBanner?()
                self?.isUpdateInProgress = false
            }
        }
    }
    
}

// MARK: - Action
private extension AmityCommunityProfileHeaderViewController {
    
    @objc func actionTap(_ sender: AmityButton) {
        switch screenViewModel.dataSource.memberStatusCommunity {
        case .guest:
            AmityHUD.show(.loading)
            screenViewModel.action.joinCommunity()
        case .member:
            break
        case .admin:
            screenViewModel.action.route(.editProfile)
        }
    }
    
    @objc func chatTap() {
        guard let rootViewController = rootViewController else { return }
        let channelRepository = AmityChannelRepository(client: AmityUIKitManager.client)
        channelToken = channelRepository.getChannel(screenViewModel.dataSource.community?.channelId ?? "").observeOnce { channel, error in
            if let channel = channel.object {
                AmityEventHandler.shared.communityChannelDidTap(from: rootViewController, channelId: channel.channelId, subChannelId: channel.defaultSubChannelId)
            }
            self.channelToken?.invalidate()
        }
    }
    
    @IBAction func postButtonTapped(_ sender: UIButton) {
        // intentionally left empty
    }
    
    @IBAction func memberButtonTapped(_ sender: UIButton) {
        screenViewModel.action.route(.member)
    }
    
    @IBAction func pendingPostsTap() {
        screenViewModel.action.route(.pendingPosts)
    }
}
