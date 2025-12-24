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
    
    public init(userId: String, userProfilePageViewModel: AmityUserProfilePageViewModel? = nil, pageId: PageId? = nil) {
        self.pageId = pageId
        
        if let userProfilePageViewModel {
            self._viewModel = StateObject(wrappedValue: userProfilePageViewModel.videoFeedViewModel)
        } else {
            self._viewModel = StateObject(wrappedValue: MediaFeedViewModel(feedType: .user(userId: userId), postType: .video))
        }
    }
    
    public var body: some View {
        VideoFeedComponent(mediaFeedViewModel: viewModel, type: .videos, pageId: pageId, componentId: .userVideoFeed)
    }
}
