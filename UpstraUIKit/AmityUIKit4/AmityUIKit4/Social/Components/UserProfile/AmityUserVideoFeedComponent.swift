//
//  AmityUserVideoFeedComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/19/24.
//

import SwiftUI

public struct AmityUserVideoFeedComponent: AmityComponentView {
    public var pageId: PageId?
    
    public var id: ComponentId {
        .userVideoFeed
    }
    
    @StateObject private var viewModel: MediaFeedViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var currentTab: VideoFeedTab = .videos
    
    private var gridLayout: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }
    
    public init(userId: String, userProfilePageViewModel: AmityUserProfilePageViewModel? = nil, pageId: PageId? = nil) {
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .userVideoFeed))
        
        if let userProfilePageViewModel {
            self._viewModel = StateObject(wrappedValue: userProfilePageViewModel.videoFeedViewModel)
        } else {
            self._viewModel = StateObject(wrappedValue: MediaFeedViewModel(feedType: .user(userId: userId), postType: .video))
        }
    }
    
    public var body: some View {
        VideoFeedComponent(mediaFeedViewModel: viewModel)
            .updateTheme(with: viewConfig)
    }
}
