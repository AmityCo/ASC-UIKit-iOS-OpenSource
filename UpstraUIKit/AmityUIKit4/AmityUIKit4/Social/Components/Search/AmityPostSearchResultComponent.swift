//
//  AmityPostSearchResultComponent.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 13/11/24.
//

import SwiftUI

public struct AmityPostSearchResultComponent: AmityComponentView {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        return .postSearchResultComponent
    }
    
    @ObservedObject private var viewModel: AmityGlobalSearchViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    
    public init(viewModel: AmityGlobalSearchViewModel, pageId: PageId? = nil) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .postSearchResultComponent))
        self.viewModel = viewModel
        
        UITableView.appearance().separatorStyle = .none
    }
    
    public var body: some View {
        ZStack {
            if viewModel.posts.isEmpty && viewModel.loadingState == .loaded {
                VStack(spacing: 15) {
                    Image(AmityIcon.noSearchableIcon.getImageResource())
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                        .frame(width: 60, height: 60)
                    
                    Text(AmityLocalizedStringSet.Social.searchNoResultsFound.localizedString)
                        .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
                }
            }
            
            if viewModel.loadingState == .loading && viewModel.posts.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<10, id: \.self) { index in
                            PostContentSkeletonView()
                                .padding(.top, index == 0 ? 8 : 0)
                        }
                    }
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.posts.enumerated()), id: \.element.postId) { index, post in
                            
                            VStack(spacing: 0) {
                                let context = AmityPostContentComponent.Context(searchKeyword: viewModel.searchKeyword)
                                AmityPostContentComponent(post: post, context: context, onTapAction: { tapContext in
                                    let context = AmityPostSearchResultComponentBehavior.Context(component: self, post: AmityPostModel(post: post), showPollResult: tapContext?.showPollResults ?? false)
                                    AmityUIKitManagerInternal.shared.behavior.postSearchResultComponentBehavior?.goToPostDetailPage(context: context)
                                })
                                
                                Rectangle()
                                    .fill(Color(viewConfig.theme.baseColorShade4))
                                    .frame(height: 8)
                                    .visibleWhen(index != viewModel.posts.count - 1)
                            }
                            .onAppear {
                                if index == viewModel.posts.count - 1 {
                                    viewModel.loadMorePosts()
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }
}
