//
//  AmityAllCategoriesPage.swift
//  AmityUIKit4
//
//  Created by Nishan on 28/8/2567 BE.
//

import SwiftUI
import UIKit

public struct AmityAllCategoriesPage: AmityPageView {
    
    public var id: PageId {
        return .allCategories
    }
    
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    @StateObject var viewConfig: AmityViewConfigController = .init(pageId: .allCategories)
    @StateObject var viewModel = CommunityCategoriesViewModel()
    
    public init() {
        UITableView.appearance().separatorStyle = .none
        
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .allCategories))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            AmityNavigationBar(title: AmityLocalizedStringSet.Social.communityAllCategoriesPageTitle.localizedString, showBackButton: true)
                .padding(.bottom, 8)
            
            List {
                ForEach(viewModel.categories) { item in
                    if #available(iOS 15.0, *) {
                        getListItem(item: item)
                            .listRowSeparator(.hidden)
                    } else {
                        getListItem(item: item)
                    }
                }
            }
            .listStyle(.plain)
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
        .onAppear {
            viewModel.fetchCategories()
        }
    }
    
    func getListItem(item: CommunityCategoryModel) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                AsyncImage(placeholder: AmityIcon.communityCategoryPlaceholder.imageResource, url: item.avatarURL)
                    .frame(width: 40, height: 40)
                    .clipped()
                    .clipShape(Circle())
                    .accessibilityIdentifier("category_row_image")
                
                Text(item.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .padding(.leading, 12)
                    .lineLimit(1)
                    .accessibilityIdentifier("category_row_name")
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
            }
            
            if let lastItemId = viewModel.categories.last?.id, lastItemId != item.id {
                Divider()
                    .overlay(Color(viewConfig.theme.baseColorShade4))
                    .padding(.vertical, 8)
                    
            }
        }
        .contentShape(Rectangle())
        .listRowBackground(Color(viewConfig.theme.backgroundColor))
        .listRowInsets(.init(top: 0, leading: 16, bottom: 0, trailing: 16))
        .onTapGesture {
            let communityListView = AmityCommunitiesByCategoryPage(categoryId: item.id)
            host.controller?.navigationController?.pushViewController(AmitySwiftUIHostingController(rootView: communityListView), animated: true)
        }
        .onAppear {
            if let lastCategoryId = viewModel.categories.last?.id, lastCategoryId == item.id {
                viewModel.loadNextPage()
            }
        }
        .onDisappear {
            viewModel.unObserveState()
        }
    }
}

#if DEBUG
#Preview {
    AmityAllCategoriesPage()
}
#endif
