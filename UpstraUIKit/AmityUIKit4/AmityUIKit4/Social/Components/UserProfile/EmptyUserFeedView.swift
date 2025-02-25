//
//  EmptyUserFeedView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/20/24.
//

import SwiftUI
enum EmptyUserFeedViewState {
    case empty, `private`, blocked
}

enum EmptyUserFeedViewType {
    case post, image, video
}

struct EmptyUserFeedView: View {
    @ObservedObject private var viewConfig: AmityViewConfigController
    private var icon: ImageResource?
    private var title: String?
    private var description: String?
    private let feedType: EmptyUserFeedViewType
    private let feedState: EmptyUserFeedViewState
    
    init(feedType: EmptyUserFeedViewType, feedState: EmptyUserFeedViewState, viewConfig: AmityViewConfigController) {
        self.viewConfig = viewConfig
        self.feedType = feedType
        self.feedState = feedState
        let emptyFeedId: ElementId
        let privateFeedId: ElementId
        let privateFeedInfoId: ElementId
        let blockedFeedId: ElementId
        let blockedFeedInfoId: ElementId
        
        switch feedType {
        case .post:
            emptyFeedId = .emptyUserFeed
            privateFeedId = .privateUserFeed
            privateFeedInfoId = .privateUserFeedInfo
            blockedFeedId = .blockedUserFeed
            blockedFeedInfoId = .blockedUserFeedInfo
        case .image:
            emptyFeedId = .emptyUserImageFeed
            privateFeedId = .privateUserImageFeed
            privateFeedInfoId = .privateUserImageFeedInfo
            blockedFeedId = .blockedUserImageFeed
            blockedFeedInfoId = .blockedUserImageFeedInfo
        case .video:
            emptyFeedId = .emptyUserVideoFeed
            privateFeedId = .privateUserVideoFeed
            privateFeedInfoId = .privateUserVideoFeedInfo
            blockedFeedId = .blockedUserVideoFeed
            blockedFeedInfoId = .blockedUserVideoFeedInfo
        }
        
        switch feedState {
        case .empty:
            icon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: emptyFeedId, key: "image", of: String.self) ?? "")
            title = viewConfig.getConfig(elementId: emptyFeedId, key: "text", of: String.self) ?? ""
            description = ""
        case .private:
            icon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: privateFeedId, key: "image", of: String.self) ?? "")
            title = viewConfig.getConfig(elementId: privateFeedId, key: "text", of: String.self) ?? ""
            description = viewConfig.getConfig(elementId: privateFeedInfoId, key: "text", of: String.self) ?? ""
        case .blocked:
            icon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: blockedFeedId, key: "image", of: String.self) ?? "")
            title = viewConfig.getConfig(elementId: blockedFeedId, key: "text", of: String.self) ?? ""
            description = viewConfig.getConfig(elementId: blockedFeedInfoId, key: "text", of: String.self) ?? ""
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let icon {
                Image(icon)
                    .renderingMode(.template)
                    .frame(width: 60, height: 60)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                    .padding(.top, 24)
            }
            
            if let title {
                Text(title)
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
            
            if let description {
                Text(description)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade3)))
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .padding(.horizontal, 16)
        .padding(.vertical, 140)
        .frame(maxWidth: 387)
        .updateTheme(with: viewConfig)
        .accessibilityIdentifier(getAccessibilityID(feedState, feedType))
    }
    
    private func getAccessibilityID(_ feedState: EmptyUserFeedViewState, _ type: EmptyUserFeedViewType) -> String {
        switch feedState {
        case .empty:
            switch type {
            case .post:
                AccessibilityID.Social.UserFeed.emptyUserFeed
            case .image:
                AccessibilityID.Social.UserFeed.emptyUserImageFeed
            case .video:
                AccessibilityID.Social.UserFeed.emptyUserVideoFeed
            }
            
        case .private:
            switch type {
            case .post:
                AccessibilityID.Social.UserFeed.privateUserFeed
            case .image:
                AccessibilityID.Social.UserFeed.privateUserImageFeed
            case .video:
                AccessibilityID.Social.UserFeed.privateUserVideoFeed
            }
            
        case .blocked:
            switch type {
            case .post:
                AccessibilityID.Social.UserFeed.blockedUserFeed
            case .image:
                AccessibilityID.Social.UserFeed.blockedUserImageFeed
            case .video:
                AccessibilityID.Social.UserFeed.blockedUserVideoFeed
            }
        }
    }
}
