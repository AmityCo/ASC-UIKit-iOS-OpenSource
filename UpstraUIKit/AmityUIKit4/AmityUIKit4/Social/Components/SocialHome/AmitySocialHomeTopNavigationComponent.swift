//
//  AmitySocialHomeTopNavigationComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/2/24.
//

import SwiftUI

public struct AmitySocialHomeTopNavigationComponent: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    public var pageId: PageId?
    
    public var id: ComponentId {
        .socialHomePageTopNavigationComponent
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var showPostCreationMenu: Bool = false
    private let selectedTab: AmitySocialHomePageTab
    private var searchButtonAction: (() -> Void)?
    
    public init(pageId: PageId? = nil, selectedTab: AmitySocialHomePageTab = .newsFeed, searchButtonAction: (() -> Void)? = nil) {
        self.pageId = pageId
        self.selectedTab = selectedTab
        self.searchButtonAction = searchButtonAction
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .socialHomePageTopNavigationComponent))
    }
    
    
    public var body: some View {
        HStack(spacing: 10) {
            let headerLabel = viewConfig.getConfig(elementId: .headerLabel, key: "text", of: String.self) ?? ""
            Text(headerLabel)
                .font(.system(size: 20, weight: .bold))
                .padding([.top, .bottom], 15.5)
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .isHidden(viewConfig.isHidden(elementId: .headerLabel), remove: true)
            
            Spacer()
            
            Button(action: {
                searchButtonAction?()
            }, label: {
                VStack {
                    let searchIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .globalSearchButton, key: "icon", of: String.self) ?? "")
                    Image(searchIcon)
                        .frame(size: CGSize(width: 21.0, height: 16.0))
                }
                .frame(size: CGSize(width: 32.0, height: 32.0))
                .background(Color(viewConfig.theme.secondaryColor.blend(.shade4)))
                .clipShape(Circle())
            })
            .isHidden(viewConfig.isHidden(elementId: .globalSearchButton), remove: true)
            
            if selectedTab != .explore {
                Button(action: {
                    
                    if selectedTab == .myCommunities {
                        goToCommunitySetupPage()
                    } else {
                        withoutAnimation {
                            showPostCreationMenu.toggle()
                        }
                    }
                    
                }, label: {
                    VStack {
                        let createButtonIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .postCreationButton, key: "icon", of: String.self) ?? "")
                        Image(createButtonIcon)
                            .frame(size: CGSize(width: 21.0, height: 16.0))
                    }
                    .frame(size: CGSize(width: 32.0, height: 32.0))
                    .background(Color(viewConfig.theme.secondaryColor.blend(.shade4)))
                    .clipShape(Circle())
                })
                .fullScreenCover(isPresented: $showPostCreationMenu) {
                    AmityCreatePostMenuComponent(isPresented: $showPostCreationMenu, pageId: pageId)
                        .background(ClearBackgroundView())
                }
                .isHidden(viewConfig.isHidden(elementId: .postCreationButton), remove: true)
            }
        }
        .padding([.leading, .trailing], 15.5)
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    
    private func goToCommunitySetupPage() {
        let context = AmitySocialHomeTopNavigationComponentBehavior.Context(component: self)
        AmityUIKitManagerInternal.shared.behavior.socialHomeTopNavigationComponentBehavior?.goToCreateCommunityPage(context: context)
    }
}



#if DEBUG
#Preview {
    AmitySocialHomeTopNavigationComponent(pageId: nil)
}
#endif
