//
//  AmityUserImageFeedComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/19/24.
//

import SwiftUI

public struct AmityUserImageFeedComponent: AmityComponentView {
    public var pageId: PageId?
    
    public var id: ComponentId {
        .userImageFeed
    }
    
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @StateObject private var viewModel: MediaFeedViewModel
    
    public init(userId: String, userProfilePageViewModel: AmityUserProfilePageViewModel? = nil, pageId: PageId? = nil) {
        self.pageId = pageId
        
        if let userProfilePageViewModel {
            self._viewModel = StateObject(wrappedValue: userProfilePageViewModel.imageFeedViewModel)
        } else {
            self._viewModel = StateObject(wrappedValue: MediaFeedViewModel(feedType: .user(userId: userId), postType: .image))
        }
    }
    
    public var body: some View {
        ImageFeedComponent(mediaFeedViewModel: viewModel, pageId: pageId, componentId: .userImageFeed)
    }
}
