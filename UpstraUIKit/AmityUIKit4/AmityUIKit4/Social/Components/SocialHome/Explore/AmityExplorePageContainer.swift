//
//  AmityExplorePageContainer.swift
//  AmityUIKit4
//
//  Created by Nishan on 27/8/2567 BE.
//

import SwiftUI
import AmitySDK

// This page acts as a container & is not public by default.
struct AmityExplorePageContainer: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    
    @State private var isRefreshing = false
    let pullToRefreshThreshold: CGFloat = 70
    
    @StateObject var stateManager = ExploreComponentsStateManager.shared
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            ZStack(alignment: .top) {
                GeometryReader { geometry in
                    
                    Color.clear
                        .frame(height: UIScreen.main.bounds.height * 0.5)
                        .onChange(of: geometry.frame(in: .named("scrollview")).origin.y) { newValue in
                            
                            // Amount scrollview is scrolled,
                            let scrollViewOffset = newValue
                            if scrollViewOffset > pullToRefreshThreshold && !isRefreshing {
                                isRefreshing = true
                                
                                Task { @MainActor in
                                    // Refresh here
                                    await refreshData()

                                    isRefreshing = false
                                }
                            }
                        }
                }
                
                ProgressView()
                    .frame(width: isRefreshing ? 20 : 0, height: isRefreshing ? 20 : 0)
                    .scaleEffect(isRefreshing ? 1 : 0)
                    .padding(.bottom, isRefreshing ? 8 : 0)
                    .opacity(isRefreshing ? 1 : 0)
                    .animation(.easeIn, value: isRefreshing)
                
                VStack(alignment: .center, spacing: 0) {
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 8)
                    
                    if stateManager.isCategoriesVisible {
                        AmityCommunityCategoriesComponent()
                            .padding(.vertical, 14)
                            .accessibilityIdentifier(AccessibilityID.Social.Explore.categoriesSection)
                    }
                    
                    if stateManager.isRecommendedCommunitiesVisible {
                        AmityRecommendedCommunitiesComponent()
                            .accessibilityIdentifier(AccessibilityID.Social.Explore.recommendedSection)
                            .padding(.top, stateManager.isCategoriesVisible ? 0 : 16)
                    }
                    
                    if stateManager.isTrendingCommunitiesVisible {
                        AmityTrendingCommunitiesComponent()
                            .accessibilityIdentifier(AccessibilityID.Social.Explore.trendingSection)
                            .padding(.top, stateManager.isRecommendedCommunitiesVisible || !stateManager.isCategoriesVisible ? 16 : 0)
                            .padding(.bottom, 8)
                    }
                }
                .padding(.top, isRefreshing ? 36 : 0)
                .animation(.linear, value: isRefreshing)
                
                emptyState
                    .opacity(stateManager.isNoCommunitiesAvailable || stateManager.isErrorInFetchingCommunities ? 1 : 0)
            }
        }
        .coordinateSpace(name: "scrollview")
    }
    
    private func openCommunitySetupPage() {
        let page = AmityCommunitySetupPage(mode: .create)
        let vc = AmitySwiftUIHostingController(rootView: page)
        host.controller?.navigationController?.pushViewController(vc, animation: .presentation)
    }
    
    @ViewBuilder
    var emptyState: some View {
        ZStack {
            Color.clear
                .frame(height: UIScreen.main.bounds.height * 0.7)
            
            VStack {
                Spacer()
                
                let emptyStateType: ExploreComponentEmptyStateView.StateType = stateManager.isNoCommunitiesAvailable ? .communitiesNotAvailable : .unableToLoad
                ExploreComponentEmptyStateView(type: emptyStateType, action: {
                    openCommunitySetupPage()
                })
                
                Spacer()
                Spacer()
            }
        }
    }
    
    func refreshData() async {
        ExploreComponentsStateManager.shared.refreshAllComponents()
        
        let minRefreshSeconds: UInt64 = 3 * 1_000_000_000
        try? await Task.sleep(nanoseconds: minRefreshSeconds)
    }
}

#if DEBUG
#Preview {
    AmityExplorePageContainer()
        .environmentObject(AmityViewConfigController(pageId: .socialHomePage))
}
#endif
