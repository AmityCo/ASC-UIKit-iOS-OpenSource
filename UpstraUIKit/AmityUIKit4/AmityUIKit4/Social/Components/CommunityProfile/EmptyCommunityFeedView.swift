//
//  EmptyCommunityFeedView.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 17/7/2567 BE.
//

import SwiftUI

public enum EmptyCommunityFeedViewType {
    case post, image, video
    
    var icon: ImageResource {
        switch self {
        case .post:
            AmityIcon.communityProfileEmptyPostIcon.imageResource
        case .image:
            AmityIcon.communityProfileEmptyImageIcon.imageResource
        case .video:
            AmityIcon.communityProfileEmptyVideoIcon.imageResource
        }
    }
    
    var description: String {
        switch self {
        case .post:
            "No post yet"
        case .image:
            "No photo yet"
        case .video:
            "No video yet"
        }
    }
}

public struct EmptyCommunityFeedView: View {
    
    @StateObject private var viewConfig: AmityViewConfigController
    
    private let feedViewType: EmptyCommunityFeedViewType
    
    public init(_ type: EmptyCommunityFeedViewType = .post) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: nil, componentId: nil))
        self.feedViewType = type
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Image(feedViewType.icon)
                .renderingMode(.template)
                .frame(width: 60, height: 60)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                .padding(.top, 24)
            
            Text(feedViewType.description)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
                .padding(.top, 8)
                .padding(.bottom, 24)
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .padding(.horizontal, 16)
        .padding(.top, 110)
        .frame(maxWidth: 387)
        .updateTheme(with: viewConfig)
    }
}
