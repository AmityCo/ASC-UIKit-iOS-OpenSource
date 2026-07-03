//
//  SocialHomePageTabSkeletonView.swift
//  AmityUIKit4
//
//  Created by Amity. All rights reserved.
//

import SwiftUI

struct SocialHomePageTabSkeletonView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { _ in
                SkeletonRectangle(height: 40, width: 68, cornerRadius: 24)
                    .shimmering(gradient: shimmerGradient)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview {
    SocialHomePageTabSkeletonView()
        .environmentObject(AmityViewConfigController(pageId: .socialHomePage))
}
#endif
