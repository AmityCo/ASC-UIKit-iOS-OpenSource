//
//  AmityCommunityProfilePage.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 9/7/2567 BE.
//

import SwiftUI
import AmitySDK

public struct AmityCommunityProfilePage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public let communityId: String
    
    @State private var showCreateBottomSheet = false
    @State private var showMenuBottomSheet = false
    @State private var isRefreshing = false
    @State private var headerComponentHeight: CGFloat = 0.0
    @State private var showStickyHeader = false
    @State private var showShareSheet = false
    
    @StateObject var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: CommunityProfileViewModel
    @State private var showPollSelectionView = false

    public var id: PageId {
        return .communityProfilePage
    }
    
    public init(communityId: String) {
        self.communityId = communityId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .communityProfilePage))
        self._viewModel = StateObject(wrappedValue: CommunityProfileViewModel(communityId: communityId))
    }
    
    func refreshData() async {
        // do work to asyncronously refresh your data here
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Header #1
            headerView
                .opacity(viewModel.startedScrollingToTop ? 0 : 1)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Note:
                    // Hack 1:
                    // We do not want the header view to move down when user tries to perform pull to refresh. So we show header #1 in the background and header #2 in foreground (inside scroll view). And we hide & show above header view based on scroll position. We do not perform offset calculation to expand/collapse single header view here because it adversely affects the scrolling performance.
                    //
                    // Hack 2:
                    // If the opacity of the view is 0, the view cannot receive any touch event. Since this scroll view is shown above header #1 in a stack, scroll view receives all touch event.
                    // To prevent this issue & receive touch event, we set the opacity of headerview #2 to be 0.01.
                    //
                    // Header #2
                    headerView
                        .opacity(!viewModel.startedScrollingToTop ? 0.01 : 1)
                    
                    if isRefreshing {
                        ProgressView()
                            .frame(width: 20, height: 20)
                            .padding(.vertical, 10)
                    }
                    
                    AmityCommunityFeedComponent(communityId: communityId, pageId: .communityProfilePage, communityProfileViewModel: viewModel, onTapAction: { post, componentContext in
                        let context = AmityCommunityProfilePageBehavior.Context(page: self, showPollResult: componentContext?.showPollResults ?? false)
                        AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToPostDetailPage(context: context, post: post, category: componentContext?.category ?? .general)
                    })
                    .isHidden(viewModel.currentTab != 0)
                    
                    AmityCommunityPinnedPostComponent(communityId: communityId, pageId: .communityProfilePage, communityProfileViewModel: viewModel, onTapAction: { post, postContext in
                        
                        let context = AmityCommunityProfilePageBehavior.Context(page: self, showPollResult: postContext?.showPollResults ?? false)
                        AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToPostDetailPage(context: context, post: post, category: postContext?.category ?? .pinAndAnnouncement)
                    })
                    .isHidden(viewModel.currentTab != 1)
                    
                    AmityCommunityImageFeedComponent(communityId: communityId, communityProfileViewModel: viewModel, pageId: .communityProfilePage)
                    .isHidden(viewModel.currentTab != 2)
                    
                    AmityCommunityVideoFeedComponent(communityId: communityId, communityProfileViewModel: viewModel, pageId: .communityProfilePage)
                    .isHidden(viewModel.currentTab != 3)
                    
                }
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: ScrollOffsetKey.self, value: geometry.frame(in: .named("scroll")).minY)
                })
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { offsetY in
                guard headerComponentHeight != 0.0 else { return }
                
                if viewModel.startedScrollingToTop != (offsetY < 0) {
                    viewModel.startedScrollingToTop.toggle()
                }
                                
                // Profile Tab Height: 46
                if showStickyHeader != (offsetY < -headerComponentHeight + 140) { //
                    withAnimation {
                        showStickyHeader.toggle()
                    }
                }
                
                if offsetY > 100  && !isRefreshing {
                    ImpactFeedbackGenerator.impactFeedback(style: .light)
                    isRefreshing = true
                    Task { @MainActor in
                        viewModel.refreshFeed()
                        await refreshData()
                        await MainActor.run {
                            isRefreshing = false
                        }
                    }
                }
            }

            stickyHeaderView
                .isHidden(!showStickyHeader, remove: true)
            
            VStack {
                topNavigationView
                    .padding(.top, 44)
                Spacer()
            }
            .bottomSheet(isShowing: $showMenuBottomSheet, height: .contentSize, sheetContent: {
                VStack(spacing: 0) {
                    
                    if let community = viewModel.community, community.isJoined {
                        
                        let optionTitle = community.hasModeratorRole ? "Community settings" : "Community information"
                        let optionIcon = community.hasModeratorRole ? AmityIcon.settingIcon.imageResource : AmityIcon.communityInformationIcon.imageResource
                        BottomSheetItemView(icon: optionIcon, text: optionTitle)
                            .onTapGesture {
                                showMenuBottomSheet.toggle()
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    let context = AmityCommunityProfilePageBehavior.Context(page: self, community: viewModel.community?.object)
                                    AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToCommunitySettingPage(context: context)

                                }
                            }
                    }
                    
                    if canShareCommunityProfileLink() {
                        let copyLinkConfig = viewConfig.forElement(.copyLink)
                        let shareLinkConfig = viewConfig.forElement(.shareLink)
                        
                        BottomSheetItemView(icon: AmityIcon.copyLinkIcon.imageResource, text: copyLinkConfig.text ?? "")
                            .onTapGesture {
                                showMenuBottomSheet.toggle()
                                
                                let profileLink = AmityUIKitManagerInternal.shared.generateShareableLink(for: .community, id: communityId)
                                UIPasteboard.general.string = profileLink
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    Toast.showToast(style: .success, message: "Link copied")
                                }
                            }
                        
                        BottomSheetItemView(icon: AmityIcon.shareToIcon.imageResource, text: shareLinkConfig.text ?? "")
                            .onTapGesture {
                                showMenuBottomSheet.toggle()
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    showShareSheet = true
                                }
                            }
                    }
                }
                .padding(.bottom, 32)
            })

            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    createPostView
                        .padding(.bottom, 30)
                }
            }
            
            PostDetailEmptyStateView()
                .visibleWhen(viewModel.showErrorState)
        }
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
        }
        .sheet(isPresented: $showShareSheet) {
            let profileLink = AmityUIKitManagerInternal.shared.generateShareableLink(for: .community, id: communityId)
            ShareActivitySheetView(link: profileLink)
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
        .edgesIgnoringSafeArea(.vertical)
    }
        
    private var headerView: some View {
        VStack(spacing: 0) {
            if let community = viewModel.community {
                
                AmityCommunityHeaderComponent(community: community, pageId: id, viewModel: viewModel, onPendingRequestBannerTap: { selectedTab in
                    let context = AmityCommunityProfilePageBehavior.Context(page: self, community: community.object, selectedTab: selectedTab)
                    AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToPendingRequestsPage(context: context)
                }, onMemberCountLabelTap: {
                    let context = AmityCommunityProfilePageBehavior.Context(page: self)
                    AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToMemberListPage(context: context, community: viewModel.community)
                })
                
                // Show the invitation banner only if the community has invitation to the user
                if let _ = viewModel.pendingCommunityInvitation {
                    AmityCommunityInvitationBanner(community: community.object, viewModel: viewModel, pageId: id)
                }
                
                AmityCommunityProfileTabComponent(currentTab: $viewModel.currentTab, pageId: .communityProfilePage)
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
            } else {
                headerSkeletonView
            }
        }
        .readSize { headerComponentHeight = $0.height }
    }
    
    private var stickyHeaderView: some View {
        VStack(spacing: 0) {
            ZStack {
                if let community = viewModel.community {
                    AsyncImage(placeholder: AmityIcon.communityProfilePlaceholder.imageResource, url: URL(string: community.largeAvatarURL) , contentMode: .fill)
                    .frame(height: 105, alignment: .top)
                    .clipped()
                }
                
                VisualEffectView(effect: UIBlurEffect(style: .regular), alpha: 1)
                    .frame(height: 105)
            }

            VStack(spacing: 0) {
                Button(action: {
                    Task { @MainActor in
                        try await viewModel.joinCommunity()
                    }
                }, label: {
                    HStack(spacing: 8) {
                        Image(AmityIcon.plusIcon.imageResource)
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(viewConfig.theme.backgroundColor))
                        Text(AmityLocalizedStringSet.Social.communityPageJoinTitle.localizedString)
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.backgroundColor)))
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                })
                .background(Color(viewConfig.theme.primaryColor))
                .clipShape(RoundedCorner())
                .padding(.all, 16)
                .isHidden(viewModel.community?.isJoined ?? false)

                AmityCommunityProfileTabComponent(currentTab: $viewModel.currentTab, pageId: .communityProfilePage)
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)

            }
            .background(Color(viewConfig.theme.backgroundColor))

            Spacer()
        }
    }

    
    private struct VisualEffectView: UIViewRepresentable {
        var effect: UIVisualEffect?
        var alpha: CGFloat
        func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
        func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
            uiView.effect = effect
            uiView.alpha = alpha
        }
    }
    
    func calculateBottomSheetHeight() -> CGFloat {
        
        let baseBottomSheetHeight: CGFloat = 68
        let itemHeight: CGFloat = 48
        let additionalItems = [
            true,
            viewModel.hasStoryManagePermission
        ].filter { $0 }
        
        let additionalHeight = CGFloat(additionalItems.count) * itemHeight
        
        return baseBottomSheetHeight + additionalHeight
    }
    
}

extension AmityCommunityProfilePage {
    
    // Create post button
    @ViewBuilder
    var createPostView: some View {
        Button(action: {
            showCreateBottomSheet.toggle()
        }, label: {
            ZStack {
                Rectangle()
                    .fill(Color(viewConfig.theme.primaryColor))
                    .clipShape(RoundedCorner())
                    .frame(width: 64, height: 64)
                    .shadow(radius: 4, y: 2)
                Image(AmityIcon.plusIcon.imageResource)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color(viewConfig.theme.backgroundColor))
            }
            
        })
        .buttonStyle(BorderlessButtonStyle())
        .padding(.trailing, 16)
        .padding(.bottom, 8)
        .bottomSheet(isShowing: $showCreateBottomSheet, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor)) {
            VStack(spacing: 0) {
                BottomSheetItemView(icon: AmityIcon.createPostMenuIcon.imageResource, text: AmityLocalizedStringSet.Social.createPostBottomSheetTitle.localizedString)
                    .onTapGesture {
                        showCreateBottomSheet.toggle()
                        host.controller?.dismiss(animated: false)
                        let context = AmityCommunityProfilePageBehavior.Context(page: self)
                        AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToPostComposerPage(context: context, community: viewModel.community)
                    }
                
                BottomSheetItemView(icon: AmityIcon.createPollMenuIcon.imageResource, text: AmityLocalizedStringSet.Social.pollLabel.localizedString, iconSize: CGSize(width: 20, height: 20))
                    .onTapGesture {
                        showCreateBottomSheet.toggle()
                        host.controller?.dismiss(animated: false)
                        
                        showPollSelectionView.toggle()
                    }
                
                BottomSheetItemView(icon: AmityIcon.createLivestreamMenuIcon.imageResource, text: AmityLocalizedStringSet.Social.liveStreamLabel.localizedString, iconSize: CGSize(width: 20, height: 20))
                    .onTapGesture {
                        showCreateBottomSheet.toggle()
                        host.controller?.dismiss(animated: false)
                        
                        let context = AmityCommunityProfilePageBehavior.Context(page: self)
                        AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToLivestreamPostComposerPage(context: context, community: viewModel.community)
                    }
                
                // Story
                if viewModel.hasStoryManagePermission {
                    BottomSheetItemView(icon: AmityIcon.createStoryMenuIcon.imageResource, text: AmityLocalizedStringSet.Social.createStoryBottomSheetTitle.localizedString)
                        .onTapGesture {
                            showCreateBottomSheet.toggle()
                            host.controller?.dismiss(animated: false)
                            let context = AmityCommunityProfilePageBehavior.Context(page: self)
                            AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToCreateStoryPage(context: context, community: viewModel.community)
                        }
                }
                
                BottomSheetItemView(icon: AmityIcon.createClipMenuIcon.imageResource, text: "Clip", iconSize: CGSize(width: 20, height: 20))
                    .onTapGesture {
                        showCreateBottomSheet.toggle()
                        host.controller?.dismiss(animated: false)
                        let context = AmityCommunityProfilePageBehavior.Context(page: self)
                        AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToClipComposerPage(context: context, community: viewModel.community)
                    }
            }
            .padding(.bottom, 32)
        }
        .bottomSheet(isShowing: $showPollSelectionView, height: .contentSize, sheetContent: {
            PollTypeSelectionView(onNextAction: { pollType in
                
                showPollSelectionView = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let context = AmityCommunityProfilePageBehavior.Context(page: self)
                    AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToPollPostComposerPage(context: context, community: viewModel.community, pollType: pollType)
                }

            })
            .environmentObject(viewConfig)
        })
        .isHidden(!viewModel.hasCreatePostPermission)
        
    }
    
    // Top navigation view
    @ViewBuilder
    var topNavigationView: some View {
        
        HStack(spacing: 0) {
            
            let backIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .backButtonElement, key: "image", of: String.self) ?? "")
            Image(backIcon)
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(Color(viewConfig.theme.backgroundColor))
                .background(
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColor.withAlphaComponent(0.5)))
                        .clipShape(RoundedCorner())
                        .padding(.all, -4)
                    
                )
                .onTapGesture {
                    host.controller?.navigationController?.popViewController(animated: true)
                }
            
            if let community = viewModel.community {
                HStack(spacing: 3) {
                    if !community.isPublic {
                        let lockIcon = AmityIcon.lockBlackIcon.imageResource
                        Image(lockIcon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(Color.white)
                            .isHidden(viewConfig.isHidden(elementId: .communityPrivateBadge))
                            .padding(.trailing, 6)
                    }
                    
                    Text(community.displayName)
                        .applyTextStyle(.titleBold(Color(viewConfig.theme.backgroundColor)))
                        .lineLimit(1)
                    
                    if community.isOfficial {
                        let verifiedBadgeIcon = AmityIcon.verifiedBadge.imageResource
                        Image(verifiedBadgeIcon)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 22, height: 22)
                            .isHidden(viewConfig.isHidden(elementId: .communityOfficialBadge))
                    }
                }
                .opacity(showStickyHeader ? 1 : 0)
                .padding(.horizontal, 12)
            }
            
            Spacer()
            
            let menuIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .menuButton, key: "image", of: String.self) ?? "")
            Image(menuIcon)
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(Color(viewConfig.theme.backgroundColor))
                .background(
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColor.withAlphaComponent(0.5)))
                        .clipShape(RoundedCorner())
                        .padding(.all, -4)
                    
                )
                .onTapGesture {
                    showMenuBottomSheet.toggle()
                }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    /// Header skeleton view
    @ViewBuilder
    var headerSkeletonView: some View {
        VStack {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade3))
                .frame(height: 188)
                .shimmering(active: true)
            
            
            VStack(alignment: .leading, spacing: 15) {
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade3))
                    .frame(width: 200, height: 12)
                    .clipShape(RoundedCorner())
                    .shimmering(gradient: shimmerGradient)
                
                HStack {
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade3))
                        .frame(width: 54, height: 12)
                        .clipShape(RoundedCorner())
                        .shimmering(gradient: shimmerGradient)
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade3))
                        .frame(width: 54, height: 12)
                        .clipShape(RoundedCorner())
                        .shimmering(gradient: shimmerGradient)
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade3))
                        .frame(width: 54, height: 12)
                        .clipShape(RoundedCorner())
                        .shimmering(gradient: shimmerGradient)
                    
                    Spacer()
                }
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade3))
                    .frame(width: 240, height: 8)
                    .clipShape(RoundedCorner())
                    .shimmering(gradient: shimmerGradient)
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade3))
                    .frame(width: 297, height: 8)
                    .clipShape(RoundedCorner())
                    .shimmering(gradient: shimmerGradient)
                
                HStack {
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade3))
                        .frame(width: 54, height: 12)
                        .clipShape(RoundedCorner())
                        .shimmering(gradient: shimmerGradient)
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade3))
                        .frame(width: 54, height: 12)
                        .clipShape(RoundedCorner())
                        .shimmering(gradient: shimmerGradient)
                    
                }
                
                AmityCommunityProfileTabComponent(currentTab: $viewModel.currentTab, pageId: .communityProfilePage)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
    
    func canShareCommunityProfileLink() -> Bool {
        guard let community = viewModel.community else { return false }
        
        let isShareableLinkConfigured = AmityUIKitManagerInternal.shared.canShareLink(for: .community)
        let isPrivateAndHidden = !community.isPublic && !community.isDiscoverable
        
        let canMemberShareLink = !isPrivateAndHidden
        let canModeratorShareLink = isPrivateAndHidden && community.hasModeratorRole
        
        return isShareableLinkConfigured && (canMemberShareLink || canModeratorShareLink)
    }
    
    func canViewCommunitySettings() -> Bool {
        return viewModel.community?.isJoined ?? false
    }
    
}
