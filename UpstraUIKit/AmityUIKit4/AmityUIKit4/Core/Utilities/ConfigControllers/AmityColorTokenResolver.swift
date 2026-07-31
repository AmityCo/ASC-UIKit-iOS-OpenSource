//
//  AmityColorTokenResolver.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 7/7/26.
//

import UIKit
import SwiftUI

/// A raw value a semantic color token resolves to: either an alias into the
/// theme palette, or a fixed hex color that is identical in every theme.
enum AmityColorTokenValue {
    case alias(AmityColorAlias)
    case hex(String)

    func uiColor(theme: AmityThemeColor) -> UIColor {
        switch self {
        case .alias(let alias):
            return alias.uiColor(theme: theme)
        case .hex(let hex):
            return UIColor(hex: hex)
        }
    }
}

extension AmityViewConfigController {
    /// Resolves a semantic color token against the current theme style and this
    /// view's page/component-scoped theme. This is the single choke point for
    /// semantic color resolution across the UIKit.
    ///
    ///     Rectangle()
    ///         .fill(Color(viewConfig.color(.surfaceTabPillActive)))
    func color(_ token: AmityColorToken) -> UIColor {
        let values = token.values
        let style = AmityUIKitConfigController.shared.getCurrentThemeStyle()
        let value = style == .dark ? values.dark : values.light
        return value.uiColor(theme: theme)
    }
}
