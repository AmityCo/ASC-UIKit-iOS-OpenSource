//
//  AmityUserSearchResultComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/23/24.
//

import SwiftUI
import AmitySDK

public struct AmityUserSearchResultComponent: AmityComponentView {
    public var pageId: PageId?
    
    public var id: ComponentId {
        .userSearchResultComponent
    }
    
    
    @ObservedObject private var viewModel: AmityGlobalSearchViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    
    init(viewModel: AmityGlobalSearchViewModel, pageId: PageId?) {
        self.viewModel = viewModel
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: nil, componentId: .communitySearchResultComponent))
    }
    
    public var body: some View {
        ZStack {
            if viewModel.users.isEmpty && viewModel.loadingState == .loaded {
                VStack(spacing: 15) {
                    Image(AmityIcon.noSearchableIcon.getImageResource())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                    
                    Text("No results found")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                }
            }
            
            List(Array(viewModel.users.enumerated()), id: \.element.userId) { index, user in
                getUserCellView(user)
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
            }
            .listRowInsets(EdgeInsets())
        }
    }
}


struct UserCellView: View {
    private let user: AmityUser
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    init(user: AmityUser) {
        self.user = user
    }
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(placeholder: AmityIcon.defaultCommunity.getImageResource(), url: URL(string: user.getAvatarInfo()?.fileURL ?? ""))
                .frame(size: CGSize(width: 40, height: 40))
                .clipShape(Circle())
            
            Text(user.displayName ?? "Unknown")
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .foregroundColor(Color(viewConfig.theme.baseColor))
            
            Spacer()
        }
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 0))
        .background(Color(viewConfig.theme.backgroundColor))
    }
}
