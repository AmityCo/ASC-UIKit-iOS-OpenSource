//
//  AmityCommunityHeaderComponent.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 12/7/2567 BE.
//

import SwiftUI

public struct AmityCommunityHeaderComponent: AmityComponentView {
    
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    
    private let community: AmityCommunityModel
    
    public var pageId: PageId?
    public var id: ComponentId {
        return .communityHeader
    }
    private var onPendingRequestBannerTap: ((_ selectedTab: AmityPendingRequestPageTab) -> Void)?
    private var onMemberCountLabelTap: (() -> Void)?
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject var viewModel: CommunityProfileViewModel
    
    public init(
        community: AmityCommunityModel,
        pageId: PageId? = nil,
        viewModel: CommunityProfileViewModel? = nil,
        onPendingRequestBannerTap: ((_ selectedTab: AmityPendingRequestPageTab) -> Void)? = nil,
        onMemberCountLabelTap: (() -> Void)? = nil
    ) {
        self.community = community
        self.pageId = pageId
        self.onPendingRequestBannerTap = onPendingRequestBannerTap
        self.onMemberCountLabelTap = onMemberCountLabelTap
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .communityHeader))
        if let viewModel {
            self._viewModel = StateObject(wrappedValue: viewModel)
        } else {
            self._viewModel = StateObject(wrappedValue: CommunityProfileViewModel(communityId: community.communityId))
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(placeholder: AmityIcon.communityProfilePlaceholder.imageResource, url: URL(string: community.largeAvatarURL) , contentMode: .fill)
                .frame(height: 188)
                .isHidden(viewConfig.isHidden(elementId: .communityCover))
                .accessibilityIdentifier(AccessibilityID.Social.CommunityHeader.communityCover)
            
            HStack(alignment: .center, spacing: 3) {
                if !community.isPublic {
                    let lockIcon = AmityIcon.lockBlackIcon.imageResource
                    Image(lockIcon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .isHidden(viewConfig.isHidden(elementId: .communityPrivateBadge))
                        .accessibilityIdentifier(AccessibilityID.Social.MyCommunities.communityPrivateBadge)
                        .padding(.trailing, 4)
                }
                
                Text(community.displayName)
                    .applyTextStyle(.headline(Color(viewConfig.theme.baseColor)))
                    .lineLimit(2)
                    .isHidden(viewConfig.isHidden(elementId: .communityName))
                
                if community.isOfficial {
                    let verifiedBadgeIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .communityVerifyBadge, key: "image", of: String.self) ?? "")

                    Image(verifiedBadgeIcon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 20, height: 20)
                        .padding(.leading, 4)
                        .isHidden(viewConfig.isHidden(elementId: .communityVerifyBadge))
                        .accessibilityIdentifier(AccessibilityID.Social.CommunityHeader.communityVerifyBadge)
                }
            }
            .padding(.bottom, 10)
            .padding([.horizontal, .top], 16)
            
            getCategoryView(community.categories)
                .isHidden(community.categories.isEmpty || viewConfig.isHidden(elementId: .communityCategory))
                .accessibilityIdentifier(AccessibilityID.Social.CommunityHeader.communityCategory)
            
            Text(community.description)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                .lineLimit(4)
                .isHidden(community.description.isEmpty || viewConfig.isHidden(elementId: .communityDescription))
                .padding(.all, 16)
                .accessibilityIdentifier(AccessibilityID.Social.CommunityHeader.communityDescription)
            
            HStack(spacing: 0) {
                Text(community.postsCount.formattedCountString)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                Text(community.postsCount == 1 ? "post" : "posts")
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                    .padding(.leading, 4)
                
                Rectangle().frame(width: 1, height: 20)
                    .foregroundColor(Color(UIColor(hex: "#E5E5E5", alpha: 1)))
                    .padding(.horizontal, 16)
                
                HStack(spacing: 0) {
                    Text(community.membersCount.formattedCountString)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                    
                    Text(community.membersCount == 1 ? "member" : "members")
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                        .padding(.leading, 4)
                }                        
                .onTapGesture {
                    onMemberCountLabelTap?()
                }
                
                Spacer()
            }
            .padding([.horizontal, .bottom], 16)
            .isHidden(viewConfig.isHidden(elementId: .communityInfo))
            .accessibilityIdentifier(AccessibilityID.Social.CommunityHeader.communityInfo)
            
            // Hide if community is joined.
            communityStatusButton
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .isHidden(viewConfig.isHidden(elementId: .communityJoinButton) || viewModel.pendingCommunityInvitation != nil)
                .accessibilityIdentifier(AccessibilityID.Social.CommunityHeader.communityJoinButton)

            
            if viewModel.isStoryTabLoading {
                SkeletonStoryTabComponent(radius: 56)
                    .frame(height: 85)
                    .padding(.bottom, 12)
                    .padding(.horizontal, 12)
            } else {
                AmityStoryTabComponent(type: .communityFeed(community.communityId))
                    .frame(height: 85)
                    .padding(.bottom, 12)
                    .isHidden(!(!viewModel.stories.isEmpty || viewModel.hasStoryManagePermission || !viewModel.roomPosts.isEmpty))
            }
            
            // Pending Posts Banner
            pendingRequestsBanner
            
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }
    
    @ViewBuilder
    var communityStatusButton: some View {
        switch viewModel.joinStatus {
        case .notJoined:
            Button(action: {
                let requiresJoinApproval = community.requiresJoinApproval
                
                AmityUserAction.perform(host: host) {
                    Task { @MainActor in
                        do {
                            try await viewModel.joinCommunity()
                            
                            let toastMessage = requiresJoinApproval ? "Requested to join. You will be notified once your request is accepted." : "You joined \(community.displayName)."
                            Toast.showToast(style: .success, message: toastMessage)
                            
                        } catch {
                            Toast.showToast(style: .warning, message: "Failed to join the community. Please try again.")
                        }
                    }
                }
            }, label: {
                HStack(spacing: 8) {
                    let plusIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .communityJoinButton, key: "image", of: String.self) ?? "")

                    Image(plusIcon)
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
            .cornerRadius(8)
        case .requested:
            Button {
                AmityUserAction.perform(host: host) {
                    Task { @MainActor in
                        await viewModel.cancelJoinRequest()
                    }
                }
            } label: {
                HStack {
                    Image(AmityIcon.cancelRequestIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    
                    Text("Cancel request")
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.secondaryColor)))
                }
            }
            .buttonStyle(AmityLineButtonStyle(viewConfig: viewConfig, size: .expanded))
        case .joined:
            EmptyView()
        }
    }

    @ViewBuilder
    var pendingRequestsBanner: some View {
        let shouldDefinitelyHideBanner = viewConfig.isHidden(elementId: .communityPendingPost) || viewModel.joinStatus != .joined
        
        if community.hasModeratorRole {
            let pendingRequestWord = WordsGrammar(count: viewModel.pendingPostCount + viewModel.joinRequestCount, singular: "Pending request", plural: "Pending requests")
            BannerView(title: pendingRequestWord.value, message: getTextForPendingRequestBanner())
                .isHidden(!viewModel.shouldShowPendingBanner || shouldDefinitelyHideBanner)
                .onTapGesture {
                    let selectedTab: AmityPendingRequestPageTab = (viewModel.pendingPostCount == 0 && viewModel.joinRequestCount > 0) ? .joinRequests : .pendingPosts
                    
                    onPendingRequestBannerTap?(selectedTab)
                }
        } else {
            let pendingRequestWord = WordsGrammar(count: viewModel.pendingPostCount, singular: "Pending request", plural: "Pending requests")
            BannerView(title: pendingRequestWord.value, message: "Your posts are pending for review")
                .isHidden(!viewModel.shouldShowPendingBanner || shouldDefinitelyHideBanner)
                .onTapGesture {
                    onPendingRequestBannerTap?(.pendingPosts)
                }
        }
    }
    
    @ViewBuilder
    private func getCategoryView(_ categories: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                    
                    HStack {
                        Text(category)
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColor)))
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .background(Color(viewConfig.theme.baseColorShade4))
                    .clipShape(RoundedCorner())
                    
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    private func getTextForPendingRequestBanner() -> String {
        var values: [String] = []
        
        let postWord = WordsGrammar(count: viewModel.pendingPostCount, set: .post)
        let requestWord = WordsGrammar(count: viewModel.joinRequestCount, singular: "join request", plural: "join requests")
                
        if viewModel.pendingPostCount > 0 {
            let countValue = viewModel.pendingPostCount > 10 ? "10+" : "\(viewModel.pendingPostCount)"
            values.append("\(countValue) \(postWord.value)")
        }
        
        if viewModel.joinRequestCount > 0 {
            let countValue = viewModel.joinRequestCount > 10 ? "10+" : "\(viewModel.joinRequestCount)"
            values.append("\(countValue) \(requestWord.value)")
        }
        
        let totalRequestCount = viewModel.pendingPostCount + viewModel.joinRequestCount
        let requireVerb = WordsGrammar(count: totalRequestCount, singular: "requires", plural: "require")
        
        let combinedWords = values.joined(separator: " and ")
        let finalText = combinedWords + " \(requireVerb.value) approval"
        return finalText
    }
    
    struct BannerView: View {
        @EnvironmentObject var viewConfig: AmityViewConfigController
        
        let title: String
        let message: String
        
        var body: some View {
            VStack(alignment: .center) {
                HStack(alignment: .center,spacing: 7) {
                    Image(AmityIcon.communityPendingPostIcon.imageResource)
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 6, height: 6)
                        .foregroundColor(Color(viewConfig.theme.primaryColor))
                    Text(title)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                }
                .padding(.top, 12)
                
                Text(message)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .background(Color(viewConfig.theme.baseColorShade4))
            .cornerRadius(4)
            .padding([.horizontal, .bottom], 16)
            .accessibilityIdentifier(AccessibilityID.Social.CommunityHeader.communityPendingPost)
        }
    }
}

