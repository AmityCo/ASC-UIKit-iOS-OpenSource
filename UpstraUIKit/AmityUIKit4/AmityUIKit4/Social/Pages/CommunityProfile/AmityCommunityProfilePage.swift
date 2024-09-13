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
    
    @State private var currentTab = 0
    @State private var showBottomSheet: Bool = false
    @State private var tabBarOffset: CGFloat = 0
    @State private var isRefreshing = false
    
    @StateObject var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: CommunityProfileViewModel
    
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
        ZStack {
            
            ScrollView(showsIndicators: false) {
                ZStack {
                    VStack(spacing: 0) {
                        
                        if let community = viewModel.community {
                            
                            AmityCommunityHeaderComponent(community: community, pageId: id, viewModel: viewModel, onPendingPostsTapAction: {
                                
                                let context = AmityCommunityProfilePageBehavior.Context(page: self, community: community.object)
                                AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToPendingPostPage(context: context)
                            }, onMemberListTapAction: {
                                
                                let context = AmityCommunityProfilePageBehavior.Context(page: self)
                                AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToMemberListPage(context: context, community: viewModel.community)
                            })
                            .offset(y: min(0, (viewModel.headerHeight - tabBarOffset)))
                            
                        }
                        // TabView
                        GeometryReader { geometry in
                            VStack(spacing: 0) {
                                
                                AmityCommunityProfileTabComponent(currentTab: $currentTab, pageId: .communityProfilePage)
                                Rectangle()
                                    .fill(Color(viewConfig.theme.baseColorShade4))
                                    .frame(height: 1)
                                
                            }
                            .offset(y: min(0, (viewModel.headerHeight - tabBarOffset)))
                            .background(Color.clear)
                            .onAppear {
                                tabBarOffset = geometry.frame(in: .global).origin.y
                            }
                            .onChange(of: geometry.frame(in: .global).origin.y) { newValue in
                                tabBarOffset = geometry.frame(in: .global).origin.y
                                if tabBarOffset > viewModel.headerHeight + 100 {
                                    isRefreshing = true
                                    Task {
                                        viewModel.refreshFeed(currentTab: currentTab)
                                        await refreshData()
                                        await MainActor.run {
                                            isRefreshing = false
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 47)
                        
                        
                        if isRefreshing {
                            ProgressView()
                                .frame(width: 20, height: 20)
                                .padding(.vertical, 10)
                        }
                        
                        AmityCommunityFeedComponent(communityId: communityId, pageId: .communityProfilePage, communityProfileViewModel: viewModel, onTapPostDetailAction: { post, category in
                            let context = AmityCommunityProfilePageBehavior.Context(page: self)
                            AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToPostDetailPage(context: context, post: post, category: category)
                        })
                            .isHidden(currentTab != 0)
                        
                        AmityCommunityPinnedPostComponent(communityId: communityId, pageId: .communityProfilePage, communityProfileViewModel: viewModel, onTapPostDetailAction: { post, category in                            
                            let context = AmityCommunityProfilePageBehavior.Context(page: self)
                            AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToPostDetailPage(context: context, post: post, category: category)
                        })
                            .isHidden(currentTab != 1 )
                        
                    }
                    .offset(y: 0)
                    
                    // Blurred View for Header
                    VStack(spacing: 0) {
                        ZStack {
                            if let community = viewModel.community {
                                
                                AsyncImage(placeholder: AmityIcon.communityProfilePlaceholder.imageResource, url: URL(string: community.largeAvatarURL) , contentMode: .fill)
                                    .frame(height: 105, alignment: .top)
                                    .clipped()
                                    .offset(y: 0)
                            }
                            VisualEffectView(effect: UIBlurEffect(style: .regular), alpha: 1)
                                .frame(height: 105)
                                .offset(y: 0)
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
                                        .foregroundColor(Color(viewConfig.theme.backgroundColor))
                                }
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                            })
                            .background(Color(viewConfig.theme.primaryColor))
                            .cornerRadius(8)
                            .padding(.all, 16)
                            .isHidden(viewModel.community?.isJoined ?? false)
                            
                            AmityCommunityProfileTabComponent(currentTab: $currentTab, pageId: .communityProfilePage)
                            Rectangle()
                                .fill(Color(viewConfig.theme.baseColorShade4))
                                .frame(height: 1)
                            
                        }
                        .background(Color(viewConfig.theme.backgroundColor))
                        
                        Spacer()
                    }
                    .opacity(tabBarOffset <= 102 ? 1 : 0)
                    .offset(y: viewModel.headerHeight - tabBarOffset)
                }
                
            }
            
            VStack {
                topNavigationView
                    .padding(.top, 44)
                Spacer()
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    createPostView
                        .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
        .edgesIgnoringSafeArea(.vertical)
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
        
        let bottomSheetHeight = calculateBottomSheetHeight()
        Button(action: {
            showBottomSheet.toggle()
        }, label: {
            ZStack {
                
                Rectangle()
                    .fill(Color(viewConfig.theme.primaryColor))
                    .clipShape(RoundedCorner())
                    .frame(width: 64, height: 64)
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
        .bottomSheet(isShowing: $showBottomSheet, height: .fixed(bottomSheetHeight), backgroundColor: Color(viewConfig.theme.backgroundColor)) {
            VStack {
                HStack(spacing: 12) {
                    // Post
                    Image(AmityIcon.createPostMenuIcon.getImageResource())
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 24)
                    
                    Button {
                        showBottomSheet.toggle()
                        host.controller?.dismiss(animated: false)
                        let context = AmityCommunityProfilePageBehavior.Context(page: self)
                        AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToPostComposerPage(context: context, community: viewModel.community)
                    } label: {
                        Text(AmityLocalizedStringSet.Social.createPostBottomSheetTitle.localizedString)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
                
                // Story
                if viewModel.hasStoryManagePermission {
                    HStack(spacing: 12) {
                        Image(AmityIcon.createStoryMenuIcon.getImageResource())
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 20, height: 24)
                        
                        Button {
                            showBottomSheet.toggle()
                            host.controller?.dismiss(animated: false)
                            let context = AmityCommunityProfilePageBehavior.Context(page: self)
                            AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToCreateStoryPage(context: context, community: viewModel.community)
                        } label: {
                            Text(AmityLocalizedStringSet.Social.createStoryBottomSheetTitle.localizedString)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(viewConfig.theme.baseColor))
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                    }
                    .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
                }
                
                Spacer()
            }
            
        }
        .isHidden(!(viewModel.community?.isJoined ?? false))
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
                HStack {
                    if !community.isPublic {
                        let lockIcon = AmityIcon.lockBlackIcon.imageResource
                        Image(lockIcon)
                            .renderingMode(.template)
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                            .isHidden(viewConfig.isHidden(elementId: .communityPrivateBadge))
                    }
                    
                    Text(community.displayName)
                        .lineLimit(1)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(viewConfig.theme.backgroundColor))
                    
                    if community.isOfficial {
                        let verifiedBadgeIcon = AmityIcon.verifiedBadge.imageResource
                        Image(verifiedBadgeIcon)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 20)
                            .padding(.leading, 2)
                            .isHidden(viewConfig.isHidden(elementId: .communityOfficialBadge))
                    }
                }
                .opacity(tabBarOffset <= 102 ? 1 : 0)
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
                    let context = AmityCommunityProfilePageBehavior.Context(page: self, community: viewModel.community?.object)
                    AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToCommunitySettingPage(context: context)
                }
        }
        .padding(.horizontal, 16)
        .padding(.top, 13)
    }
    
    /// Header skeleton view
    @ViewBuilder
    var headerSkeletonView: some View {
        VStack {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade3))
                .frame(height: 188)
                .shimmering(active: true)
            
            
            VStack(alignment: .leading) {
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
            }
            .padding(.horizontal, 16)
        }
    }
    
}
