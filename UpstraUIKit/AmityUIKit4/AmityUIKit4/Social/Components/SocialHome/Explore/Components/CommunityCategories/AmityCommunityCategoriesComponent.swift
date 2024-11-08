//
//  AmityCommunityCategoriesComponent.swift
//  AmityUIKit4
//
//  Created by Nishan on 28/8/2567 BE.
//

import SwiftUI

public struct AmityCommunityCategoriesComponent: AmityComponentView {
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        return .communityCategories
    }
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel = CommunityCategoriesViewModel(limit: 5)
    
    private let maxCategoriesCount: Int = 5
    
    public init(pageId: PageId? = .socialHomePage) {
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .communityCategories))
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            ExploreCategorySkeletonView()
                .opacity(viewModel.categories.isEmpty && viewModel.queryState == .loading ? 1 : 0)

            content
                .opacity(viewModel.categories.isEmpty ? 0 : 1)
        }
        .onAppear {
            viewModel.observeState()
            viewModel.fetchCategories(limit: 5)
        }
        .onDisappear {
            viewModel.unObserveState()
        }
        .updateTheme(with: viewConfig)
    }
    
    @ViewBuilder
    var content: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(viewModel.categories) { item in
                    CategoryLabel(category: item) {
                        let communityListView = AmityCommunitiesByCategoryPage(categoryId: item.id)
                        host.controller?.navigationController?.pushViewController(AmitySwiftUIHostingController(rootView: communityListView), animated: true)
                    }
                }
                
                if viewModel.loadedCategoriesCount > maxCategoriesCount {
                    MoreLabel {
                        let allCategoriesView = AmityAllCategoriesPage()
                        host.controller?.navigationController?.pushViewController(AmitySwiftUIHostingController(rootView: allCategoriesView), animated: true)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal)
    }
}

struct CategoryLabel: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    let category: CommunityCategoryModel
    let tapAction: DefaultTapAction
    
    var body: some View {
        Button(action: {
            tapAction()
        }, label: {
            HStack(spacing: 0) {
                AsyncImage(placeholder: AmityIcon.communityCategoryPlaceholder.imageResource, url: category.avatarURL)
                    .scaledToFill()
                    .clipped()
                    .frame(width: 28, height: 28)
                    .cornerRadius(14, corners: .allCorners)
                
                Text(category.name)
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                    .padding(.horizontal, 8)
            }
            .padding(4)
            .frame(minHeight: 36)
            .overlay(
                RoundedCorner()
                    .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
            )
        })
        .buttonStyle(.plain)
    }
}

struct MoreLabel: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    let tapAction: DefaultTapAction
    
    var body: some View {
        Button(action: {
            tapAction()
        }, label: {
            HStack(spacing: 0) {
                Text(AmityLocalizedStringSet.Social.exploreCategoriesSeeMore.localizedString)
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                    .padding(.horizontal, 8)
                
                Image(systemName: "chevron.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .padding(.trailing, 8)
            }
            .padding(4)
            .frame(minHeight: 36)
            .overlay(
                RoundedCorner()
                    .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
            )
        })
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    AmityCommunityCategoriesComponent()
}
#endif
