//
//  AmityProductTagBadgeView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/18/26.
//

import SwiftUI

struct AmityProductTagBadgeView: View {
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(AmityIcon.tagIcon.imageResource)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
                .foregroundColor(.white)
            Text("\(count)")
                .applyTextStyle(.captionBold(.white))
                .isHidden(count == 0)
        }
        .padding(.horizontal, count > 0 ? 8 : 6)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.black.opacity(0.5)))
    }
}
