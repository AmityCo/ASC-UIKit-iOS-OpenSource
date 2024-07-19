//
//  EmptyCommunityFeedView.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 17/7/2567 BE.
//

import SwiftUI

public struct EmptyCommunityFeedView: View {
    
    @StateObject private var viewConfig: AmityViewConfigController
    
    public init() {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: nil, componentId: nil))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Image(AmityIcon.communityProfileEmptyPostIcon.imageResource)
                .renderingMode(.template)
                .frame(width: 60, height: 60)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                .padding(.top, 24)
            
            Text("No post yet")
                .font(.system(size: 17))
                .padding(.top, 8)
                .padding(.bottom, 24)
                .foregroundColor(Color(viewConfig.theme.baseColorShade3))
            
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .padding(.horizontal, 16)
        .padding(.vertical, 175)
        .frame(maxWidth: 387)
        .updateTheme(with: viewConfig)
    }
}
