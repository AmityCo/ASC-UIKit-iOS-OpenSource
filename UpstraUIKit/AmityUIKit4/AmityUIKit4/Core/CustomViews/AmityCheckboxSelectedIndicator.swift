//
//  AmityCheckboxSelectedIndicator.swift
//  AmityUIKit4
//
//  The "selected" state of a poll checkbox: a primary-color filled circle
//  with a white checkmark. Replaces the flat checkbox asset so the fill
//  follows the configured `primaryColor` while keeping the white check.
//

import SwiftUI

struct AmityCheckboxSelectedIndicator: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController

    private let size: CGFloat

    /// - Parameter size: outer diameter of the indicator. The checkmark is
    ///   sized proportionally (50% of `size`).
    init(size: CGFloat = 20) {
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(viewConfig.theme.primaryColor))
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundColor(Color(AmityFixedColor.shared.white))
        }
        .frame(width: size, height: size)
    }
}
