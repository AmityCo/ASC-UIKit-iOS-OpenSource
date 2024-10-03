//
//  AmityUserSearchResultComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/23/24.
//

import SwiftUI
import AmitySDK

public struct AmityUserSearchResultComponent: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        .userSearchResultComponent
    }
    
    @ObservedObject private var viewModel: AmityGlobalSearchViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    
    public init(viewModel: AmityGlobalSearchViewModel, pageId: PageId? = nil) {
        self.viewModel = viewModel
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: nil, componentId: .communitySearchResultComponent))
    }
    
    public var body: some View {
        ZStack {
            if viewModel.users.isEmpty && viewModel.loadingState == .loaded {
                VStack(spacing: 15) {
                    Image(AmityIcon.noSearchableIcon.getImageResource())
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                        .frame(width: 60, height: 60)
                    
                    Text("No results found")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                }
            }
            
            List(Array(viewModel.users.enumerated()), id: \.element.userId) { index, user in
                getUserCellView(user)
                .background(Color(viewConfig.theme.backgroundColor))
                .onTapGesture {
                    let context = AmityUserSearchResultComponentBehavior.Context(component: self, user: user)
                    AmityUIKitManagerInternal.shared.behavior.userSearchResultComponentBehavior?.goToUserProfilePage(context: context)
                }
                .onAppear {
                    if index == viewModel.users.count - 1 {
                        viewModel.loadMoreUsers()
                    }
                }
            }
            .listStyle(.plain)
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }
    
    
    @ViewBuilder
    func getUserCellView(_ user: AmityUser) -> some View {
        if #available(iOS 15.0, *) {
            VStack(spacing: 0) {
                UserCellView(user: user)
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 0))
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
                    .padding([.leading, .trailing], 16)
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden, edges: .all)
        } else {
            VStack(spacing: 0) {
                UserCellView(user: user)
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 0))
            }
            .listRowInsets(EdgeInsets())
        }
    }
}


struct UserCellView: View {
    private let user: AmityUser
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    private var menuButtonAction: ((AmityUser) -> Void)? = nil
    
    init(user: AmityUser, menuButtonAction: ((AmityUser) -> Void)? = nil) {
        self.user = user
        self.menuButtonAction = menuButtonAction
    }
    
    var body: some View {
        HStack(spacing: 0) {
            AmityUserProfileImageView(displayName: user.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString, avatarURL: URL(string: user.getAvatarInfo()?.fileURL ?? ""))
                .frame(size: CGSize(width: 40, height: 40))
                .clipShape(Circle())
            
            Text(user.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .padding(.leading, 8)
                        
            Image(AmityIcon.brandBadge.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .padding(.leading, 4)
                .opacity(user.isBrand ? 1 : 0)
            
            if let menuButtonAction {
                Spacer()
                Button {
                    menuButtonAction(user)
                } label: {
                    Image(AmityIcon.threeDotIcon.getImageResource())
                        .renderingMode(.template)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 24, height: 18)
                }
            } else {
                Spacer()
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }
}
