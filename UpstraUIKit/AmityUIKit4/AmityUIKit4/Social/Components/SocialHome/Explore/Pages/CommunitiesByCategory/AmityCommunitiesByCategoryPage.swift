//
//  AmityCommunitiesByCategoryPage.swift
//  AmityUIKit4
//
//  Created by Nishan on 4/9/2567 BE.
//

import SwiftUI

public struct AmityCommunitiesByCategoryPage: AmityPageView {
    
    public var id: PageId {
        return .communitiesByCategoryPage
    }
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject var viewConfig: AmityViewConfigController
    @StateObject var viewModel: CommunityListViewModel
    
    public init(categoryId: String) {
        self._viewModel = StateObject(wrappedValue: CommunityListViewModel(categoryId: categoryId))
        self._viewConfig = StateObject(wrappedValue: .init(pageId: .communitiesByCategoryPage))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            AmityNavigationBar(title: viewModel.categoryName, showBackButton: true)
            
            CommunityListView(viewModel: viewModel)
                .padding(.top, 16)
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
        }
    }
}

#if DEBUG
#Preview {
    AmityCommunitiesByCategoryPage(categoryId: "1234")
}
#endif
