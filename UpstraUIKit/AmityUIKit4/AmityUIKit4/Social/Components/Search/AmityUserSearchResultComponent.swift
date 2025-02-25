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
        
        UITableView.appearance().separatorStyle = .none
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
                        .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
                }
            }
            
            if viewModel.loadingState == .loading && viewModel.users.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<20, id: \.self) { index in
                            UserCellSkeletonView()
                                .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .padding(.top, index == 0 ? 8 : 0)
                        }
                    }
                }
            } else {
                List(Array(viewModel.users.enumerated()), id: \.element.userId) { index, user in
                    getUserCellView(user)
                        .background(Color(viewConfig.theme.backgroundColor))
                        .padding(.top, index == 0 ? 8 : 0)
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
            
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }
    
    
    @ViewBuilder
    func getUserCellView(_ user: AmityUser) -> some View {
        if #available(iOS 15.0, *) {
            VStack(spacing: 0) {
                UserCellView(user: user)
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden, edges: .all)
        } else {
            VStack(spacing: 0) {
                UserCellView(user: user)
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .listRowInsets(EdgeInsets())
        }
    }
}
