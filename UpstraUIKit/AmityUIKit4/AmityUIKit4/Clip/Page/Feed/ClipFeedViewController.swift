//
//  ClipFeedViewController.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 23/6/25.
//

import UIKit
import Foundation
import SwiftUI
import AVFoundation

struct ClipFeedView: View {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    // Initialize provider here & pass it to collection view
    @StateObject
    var clipProvider: ClipService
    var onTapAction: ((ClipFeedAction) -> Void)?
    
    init(clipProvider: ClipService, onTapAction: ((ClipFeedAction) -> Void)? = nil) {
        self._clipProvider = StateObject(wrappedValue: clipProvider)
        self.onTapAction = onTapAction
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            ClipFeedEmptyStateView(onTapAction: { action in
                switch action {
                case .exploreCommunity:
                    onTapAction?(.exploreCommunity)
                case .createCommunity:
                    onTapAction?(.createCommunity)
                default:
                    break
                }
            })
            .visibleWhen(clipProvider.loadingState == .loaded && clipProvider.clips.isEmpty)
            
            ClipFeedLoadingStateView(isError: clipProvider.loadingState == .error)
                .visibleWhen((clipProvider.loadingState == .loading && clipProvider.clips.isEmpty) || clipProvider.loadingState == .error)
            
            ClipFeedContainerView(provider: clipProvider)
                .visibleWhen(clipProvider.loadingState == .loaded && !clipProvider.clips.isEmpty)
            
            navigationBar
        }
        .onAppear {
            clipProvider.load()
        }
    }
    
    @ViewBuilder
    var navigationBar: some View {
        HStack {
            Button {
                host.controller?.navigationController?.popViewController(animated: true)
            } label: {
                Image(AmityIcon.backIcon.imageResource)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 24, height: 20)
                    .foregroundColor(.white)
                    .padding(6)
            }
            
            Spacer()
            
            ZStack {
                SkeletonRectangle(height: 8, width: 120, color: viewConfig.theme.secondaryColor.blend(.shade2))
                    .visibleWhen(clipProvider.loadingState == .loading && clipProvider.clips.isEmpty)
                
                Button {
                    guard let post = clipProvider.getActiveClipPost() else { return }
                    
                    switch post.postTargetType {
                    case .community:
                        guard let communityId = post.targetCommunity?.communityId else { return }
                        openCommunityProfilePage(communityId: communityId)
                    default:
                        let userId = post.postedUserId
                        openUserProfilePage(userId: userId)
                    }
                                        
                } label: {
                    navigationTitle
                }
                .buttonStyle(.plain)
                .visibleWhen(clipProvider.loadingState == .loaded && !clipProvider.clips.isEmpty)
            }
            
            Spacer()
            
            Button {
                // Pause all players
                AVPlayerLayerCache.shared.pauseAllPlayers()
                
                openClipComposerPage()
            } label: {
                Image(AmityIcon.clipFeedCameraIcon.imageResource)
                    .padding(6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .foregroundColor(.white)
        .frame(minHeight: host.controller?.navigationController?.navigationBar.frame.height ?? 44)
    }
    
    @ViewBuilder
    var navigationTitle: some View {
        HStack(spacing: 8) {
            let post = clipProvider.getActiveClipPost()
                        
            if let post, post.postTargetType == .community {
                if !post.isTargetPublicCommunity {
                    Image(AmityIcon.getImageResource(named: "lockBlackIcon"))
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundColor(Color.white)
                        .frame(width: 16, height: 16)
                }
                
                Text(post.targetCommunity?.displayName ?? "Unknown")
                    .applyTextStyle(.titleBold(Color.white))
                    .lineLimit(1)
                
                if post.isTargetOfficialCommunity {
                    let verifiedBadgeIcon = AmityIcon.getImageResource(named: "verifiedBadge")
                    Image(verifiedBadgeIcon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 16, height: 16)
                        .isHidden(viewConfig.isHidden(elementId: .communityOfficialBadge))
                }
            } else {
                Text(post?.postedUser?.displayName ?? "")
                    .applyTextStyle(.titleBold(Color.white))
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
    }
    
    func openClipComposerPage() {
        let view = AmityPostTargetSelectionPage(context: AmityPostTargetSelectionPage.Context(isClipPost: true))
        let controller = AmitySwiftUIHostingController(rootView: view)
        
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.navigationBar.isHidden = true
        
        self.host.controller?.present(navigationController, animated: true)
    }
    
    func openCommunityProfilePage(communityId: String) {
        let page = AmityCommunityProfilePage(communityId: communityId)
        let hostController = AmitySwiftUIHostingController(rootView: page)
        host.controller?.navigationController?.pushViewController(hostController, animated: true)
    }
    
    func openUserProfilePage(userId: String) {
        let userProfilePage = AmityUserProfilePage(userId: userId)
        let controller = AmitySwiftUIHostingController(rootView: userProfilePage)
        host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
}

// Container for UICollectionView based UIViewController
struct ClipFeedContainerView: UIViewControllerRepresentable {
    
    let provider: ClipService
    
    func makeUIViewController(context: Context) -> ClipFeedViewController {
        let controller = ClipFeedViewController()
        controller.provider = provider
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ClipFeedViewController, context: Context) {
        
    }
}

class ClipFeedViewController: UIViewController {
    
    private var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        return layout
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .white
        
        return collectionView
    }()
    
    var provider: ClipService!
    
    // If startIndex is not 0, we need to scroll to particular index when collection view loads. This property
    // keeps track of that index.
    var isScrolledToParticularIndex = false
    var isFeedVisible = true
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        
        provider.onLoadCompletion = { [weak self] in
            guard let self, isFeedVisible else { return }
            
            Log.add(event: .info, "✅ FeedCollectionView loaded...")
            
            // Load collection view
            collectionView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        isFeedVisible = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        isFeedVisible = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
                
        isFeedVisible = false
        
        // Pause video
        if let cell = collectionView.cellForItem(at: IndexPath(row: provider.currentIndex, section: 0)) as? ClipFeedViewCell {
            cell.pauseVideo()
        }
    }
    
    func setupViews() {
        // Hide Navigation Bar
        navigationController?.navigationBar.isHidden = true
        
        view.backgroundColor = .clear
        collectionView.backgroundColor = .clear

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        collectionView.register(ClipFeedViewCell.self, forCellWithReuseIdentifier: ClipFeedViewCell.identifier)
    }

    // Call CollectionView.reloadData() first before calling this
    func updateCollectionView(startAt: Int) {
        if startAt != 0  {
            let collectionViewItems = collectionView.numberOfItems(inSection: 0)
            collectionView.scrollToItem(at: IndexPath(row: startAt, section: 0), at: .centeredVertically, animated: false)
        } else {
            collectionView.reloadData()
        }
    }
    
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            Log.warn("Failed to setup audio session: \(error)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        AVPlayerLayerCache.shared.flushCacheItem()
    }
}

extension ClipFeedViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return provider.clips.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ClipFeedViewCell.identifier, for: indexPath) as! ClipFeedViewCell
        
        let clipPost = provider.clips[indexPath.row]
        cell.onTapAction = { [weak self] action in
            guard let self else { return }
            switch action {
            case .commentTray(let post):
                self.openCommentTrayPage(post: post)
            case .postDetail(let post):
                self.openPostDetailPage(post: post)
            case .userProfile(let userId):
                self.openUserProfilePage(userId: userId)
            case .watchNextClip:
                self.moveToNextClip()
            default:
                break
            }
        }
        
        cell.configure(clip: clipPost)
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! ClipFeedViewCell
        let clipPost = provider.clips[indexPath.row]
        cell.configure(clip: clipPost)
        
        if indexPath.row == provider.currentIndex && isFeedVisible {
            cell.playVideo()
        }
        
        if !isScrolledToParticularIndex && provider.startIndex != 0 {
            // Scroll to item
            collectionView.scrollToItem(at: IndexPath(row: provider.startIndex, section: 0), at: .centeredVertically, animated: false)
            
            isScrolledToParticularIndex = true
        }
        
        if provider.clips.last?.id == clipPost.id && provider.canLoadMore() {
            provider.loadMore()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! ClipFeedViewCell
        cell.pauseVideo()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageIndex = Int(scrollView.contentOffset.y / scrollView.bounds.height)
        if pageIndex != provider.currentIndex {
            provider.setActiveClipIndex(index: pageIndex)
            
            // Autoplay video when moved to next video
            autoPlayVideo()
        }
    }
    
    func autoPlayVideo() {
        if let cell = collectionView.cellForItem(at: IndexPath(row: provider.currentIndex, section: 0)) as? ClipFeedViewCell, isFeedVisible {
            cell.playVideo()
        }
    }
    
    func moveToNextClip() {
        let itemsCount = collectionView.numberOfItems(inSection: 0)
        
        let nextIndex = provider.currentIndex + 1
        if nextIndex < itemsCount {
            collectionView.scrollToItem(at: IndexPath(row: nextIndex, section: 0), at: .centeredVertically, animated: false)
        }
    }
}

// Navigations
extension ClipFeedViewController {
    
    func openUserProfilePage(userId: String) {
        isFeedVisible = false
        
        let userProfilePage = AmityUserProfilePage(userId: userId)
        let controller = AmitySwiftUIHostingController(rootView: userProfilePage)
        
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func openPostDetailPage(post: AmityPostModel) {
        isFeedVisible = false
        
        let postComponentContext = AmityPostContentComponent.Context()
        let vc = AmitySwiftUIHostingController(rootView: AmityPostDetailPage(post: post.object, context: postComponentContext))
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func openCommentTrayPage(post: AmityPostModel) {
        isFeedVisible = false
        
        var shouldAllowInteraction = true
        if let targetCommunity = post.targetCommunity, !targetCommunity.isJoined {
            shouldAllowInteraction = false
        }
        
        let trayUI = AmityCommentTrayComponent(referenceId: post.postId, referenceType: .post, shouldAllowInteraction: shouldAllowInteraction ,shouldAllowCreation: true)
        let hostingController = AmitySwiftUIHostingController(rootView: trayUI)
        hostingController.modalPresentationStyle = .pageSheet
        
        if #available(iOS 15.0, *) {
            if let sheet = hostingController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
        }
        self.present(hostingController, animated: true)
    }
}
