//
//  AmityMediaFeedContainer.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 31/10/25.
//

import SwiftUI
import AmitySDK

enum MediaFeedTab: String, Identifiable {
    case photos
    case videos
    case clips

    var id: String {
        return self.rawValue
    }
}

struct AmityMediaFeedContainer: View {
    
    enum ContainerType {
        case user
        case community
    }
    
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    
    let pageId: PageId?
    let type: ContainerType
    
    @StateObject
    private var viewConfig: AmityViewConfigController

    @State private var currentTab: MediaFeedTab = .photos
    @StateObject var imageFeedModel: MediaFeedViewModel
    @StateObject var videoFeedModel: MediaFeedViewModel
        
    init(pageId: PageId?, type: ContainerType, imageFeedModel: MediaFeedViewModel, videoFeedModel: MediaFeedViewModel) {
        self.pageId = pageId
        self.type = type
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId))
        self._imageFeedModel = StateObject(wrappedValue: imageFeedModel)
        self._videoFeedModel = StateObject(wrappedValue: videoFeedModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if imageFeedModel.emptyFeedState != .private {
                HStack {
                    ChipTabButton(title: "Photos", selected: currentTab == .photos) {
                        currentTab = .photos
                    }
                    
                    ChipTabButton(title: "Videos", selected: currentTab == .videos) {
                        currentTab = .videos
                    }
                    
                    ChipTabButton(title: "Clips", selected: currentTab == .clips) {
                        currentTab = .clips
                    }
                    
                    Spacer()
                }
                .padding(.top, 14)
                .padding(.horizontal, 16)
            }
            
            switch currentTab {
            case .photos:
                ImageFeedComponent(mediaFeedViewModel: imageFeedModel, pageId: pageId, componentId: type == .user ? .userImageFeed : .communityImageFeed)
            case .videos:
                VideoFeedComponent(mediaFeedViewModel: videoFeedModel, type: .videos, pageId: pageId, componentId: type == .user ? .userVideoFeed : .communityVideoFeed)
            case .clips:
                VideoFeedComponent(mediaFeedViewModel: videoFeedModel, type: .clips, pageId: pageId, componentId: type == .user ? .userVideoFeed : .communityVideoFeed)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
        .onChange(of: currentTab) { tab in
            handleDataChanges(tab: tab)
        }
        .onChange(of: imageFeedModel.currentFeedSources) { _ in
            handleDataChanges(tab: currentTab)
        }
        .onChange(of: videoFeedModel.currentFeedSources) { _ in
            handleDataChanges(tab: currentTab)
        }
        .onAppear {
            switch currentTab {
            case .photos:
                if imageFeedModel.hasNavigatedToPostDetail {
                    imageFeedModel.hasNavigatedToPostDetail = false
                } else {
                    imageFeedModel.loadMediaFeed()
                }
            case .videos, .clips:
                if videoFeedModel.hasNavigatedToPostDetail {
                    videoFeedModel.hasNavigatedToPostDetail = false
                } else {
                    videoFeedModel.loadMediaFeed(feedTab: currentTab == .videos ? .videos : .clips)
                }
            }
        }
    }
    
    func handleDataChanges(tab: MediaFeedTab) {
        switch tab {
        case .photos:
            imageFeedModel.loadMediaFeed()
        case .videos:
            videoFeedModel.loadMediaFeed(feedTab: .videos)
        case .clips:
            videoFeedModel.loadMediaFeed(feedTab: .clips)
        }
    }
}
