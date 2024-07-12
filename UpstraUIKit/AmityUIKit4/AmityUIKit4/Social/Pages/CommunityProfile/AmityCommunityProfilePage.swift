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
    @State private var tabBarOptions: [CommunityPageTabItem] = [CommunityPageTabItem(index: 0, image: AmityIcon.communityFeedIcon.imageResource)]
    @State private var showBottomSheet: Bool = false
    
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
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    
                    if let community = viewModel.community {
                        AmityCommunityHeaderComponent(community: community, pageId: id) {
                            let context = AmityCommunityProfilePageBehavior.Context(page: self)
                            AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToPendingPostPage(context: context)
                        }
                    } else {
                        headerSkeletonView
                    }
                    
                    CommunityPageTabBarView(currentTab: $currentTab, tabBarOptions: $tabBarOptions)
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 1)
                    
                    AmityCommunityFeedComponent(communityId: communityId, pageId: id)
                }
                .edgesIgnoringSafeArea([.top, .bottom])
                .updateTheme(with: viewConfig)
                
                createPostView
            }
            .onAppear {
                host.controller?.navigationController?.isNavigationBarHidden = true
            }
            
            topNavigationView
        }
    }
    
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
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color(viewConfig.theme.backgroundColor))
            }
            
        })
        .buttonStyle(BorderlessButtonStyle())
        .padding(.trailing, 16)
        .padding(.bottom, 8)
        .bottomSheet(isShowing: $showBottomSheet, height: bottomSheetHeight, backgroundColor: Color(viewConfig.theme.backgroundColor)) {
            VStack {
                HStack(spacing: 12) {
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
                
                Spacer()
            }
            
        }
        .isHidden(!(viewModel.community?.isJoined ?? false))
    }
    
    
    func calculateBottomSheetHeight() -> CGFloat {
        
        let baseBottomSheetHeight: CGFloat = 68
        let itemHeight: CGFloat = 48
        let additionalItems = [
            true
        ].filter { $0 }
        
        let additionalHeight = CGFloat(additionalItems.count) * itemHeight
        
        return baseBottomSheetHeight + additionalHeight
    }
    
    
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
    
    @ViewBuilder
    var topNavigationView: some View {
        
        HStack {
            Image(AmityIcon.backIcon.imageResource)
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
            Spacer()
            Image(AmityIcon.threeDotIcon.imageResource)
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
                    let context = AmityCommunityProfilePageBehavior.Context(page: self)
                    AmityUIKitManagerInternal.shared.behavior.communityProfilePageBehavior?.goToCommunitySettingPage(context: context)
                }
        }
        .padding(.horizontal, 16)
        .padding(.top, 23)
    }
    
}

#if DEBUG
#Preview {
    AmityCommunityProfilePage(communityId: "")
}
#endif
