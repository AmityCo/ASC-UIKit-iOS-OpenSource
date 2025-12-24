//
//  AmityCommunityImageFeedComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/9/24.
//

import SwiftUI

public struct AmityCommunityImageFeedComponent: AmityComponentView {
    
    public var id: ComponentId {
        .communityImageFeed
    }
    
    public var pageId: PageId?
    @StateObject private var viewModel: MediaFeedViewModel
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    
    public init(communityId: String, communityProfileViewModel: CommunityProfileViewModel? = nil, pageId: PageId? = nil) {
        self.pageId = pageId
        
        if let communityProfileViewModel {
            self._viewModel = StateObject(wrappedValue: communityProfileViewModel.imageFeedViewModel)
        } else {
            self._viewModel = StateObject(wrappedValue: MediaFeedViewModel(feedType: .community(communityId: communityId), postType: .image))
        }
    }
    
    public var body: some View {
        ImageFeedComponent(mediaFeedViewModel: viewModel, pageId: pageId, componentId: .communityImageFeed)
    }
}
