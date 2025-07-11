//
//  AmityCommunityVideoFeedComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/11/24.
//

import SwiftUI

public struct AmityCommunityVideoFeedComponent: AmityComponentView {
    public var pageId: PageId?
    @StateObject private var viewModel: MediaFeedViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    
    @State private var currentTab: VideoFeedTab = .videos
    
    public var id: ComponentId {
        .communityVideoFeed
    }
    
    private var gridLayout: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }
    
    public init(communityId: String, communityProfileViewModel: CommunityProfileViewModel? = nil, pageId: PageId? = nil) {
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .communityVideoFeed))
        
        if let communityProfileViewModel {
            self._viewModel = StateObject(wrappedValue: communityProfileViewModel.videoFeedViewModel)
        } else {
            self._viewModel = StateObject(wrappedValue: MediaFeedViewModel(feedType: .community(communityId: communityId), postType: .video))
        }
    }
    
    public var body: some View {
        VideoFeedComponent(mediaFeedViewModel: viewModel)
            .updateTheme(with: viewConfig)
    }
}
