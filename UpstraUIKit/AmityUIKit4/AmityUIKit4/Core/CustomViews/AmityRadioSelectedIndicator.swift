//
//  AmityRadioSelectedIndicator.swift
//  AmityUIKit4
//
//  The "selected" state of a radio button: a primary-color filled circle
//  with a white inner dot. Replaces the flat `pollRadioIcon` asset so the
//  ring follows the configured `primaryColor` while keeping the white dot.
//

import SwiftUI

struct AmityRadioSelectedIndicator: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController

    private let size: CGFloat

    /// - Parameter size: outer diameter of the indicator. The inner white dot
    ///   is sized proportionally (40% of `size`).
    init(size: CGFloat = 20) {
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(viewConfig.theme.primaryColor))
            Circle()
                .fill(Color(AmityFixedColor.shared.white))
                .frame(width: size * 0.4, height: size * 0.4)
        }
        .frame(width: size, height: size)
    }
}
