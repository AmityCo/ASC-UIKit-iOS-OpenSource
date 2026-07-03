//
//  SocialHomeFeedSkeletonView.swift
//  AmityUIKit4
//
//  Created by Amity. All rights reserved.
//

import SwiftUI

struct SocialHomeFeedSkeletonView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController

    var body: some View {
        List {
            // Story / clip avatar row
            VStack(spacing: 0) {
                SkeletonStoryTabComponent(radius: 64)
                    .frame(height: 118)
                    .padding(.leading, 18)
                    .shimmering(gradient: shimmerGradient)
                    .background(Color(viewConfig.theme.backgroundColor))

                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 8)
            }
            .listRowInsets(EdgeInsets())
            .modifier(HiddenListSeparator())

            // Post skeletons
            ForEach(0..<5, id: \.self) { _ in
                VStack(spacing: 0) {
                    PostContentSkeletonView()
                }
                .listRowInsets(EdgeInsets())
                .modifier(HiddenListSeparator())
            }
        }
        .listStyle(.plain)
        .disabled(true)
    }
}

#if DEBUG
#Preview {
    SocialHomeFeedSkeletonView()
        .environmentObject(AmityViewConfigController(pageId: .socialHomePage))
}
#endif
