//
//  PrivateCommunityFeedView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/21/25.
//

import SwiftUI

public struct PrivateCommunityFeedView: View {
    
    @StateObject private var viewConfig: AmityViewConfigController
    
    public init(_ type: EmptyCommunityFeedViewType = .post) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: nil, componentId: nil))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Image(AmityIcon.privateFeedIcon.getImageResource())
                .renderingMode(.template)
                .frame(width: 60, height: 60)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                .padding(.top, 24)
            
            Text("This community is private")
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
                .padding(.top, 8)
                .padding(.bottom, 4)
            
            Text("Join this community to see its content and members.")
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade3)))
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .padding(.horizontal, 16)
        .padding(.vertical, 160)
        .frame(maxWidth: 387)
        .updateTheme(with: viewConfig)
    }
}
