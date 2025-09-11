//
//  AmityPaddingModifier.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 18/7/25.
//

import SwiftUI

enum AmitySpacingStyle: CGFloat {
    case none = 0
    case spacingXXS = 2
    case spacingXS = 4
    case spacingSM = 6
    case spacingMD = 8
    case spacingLG = 12
    case spacingXL = 16
    case spacing2XL = 20
    case spacing3XL = 24
    case spacing4XL = 32
    case spacing5XL = 40
    case spacing6XL = 48
}

extension View {
    
    nonisolated func padding(_ edges: Edge.Set = .all, style: AmitySpacingStyle) -> some View {
        return self
            .padding(edges, style.rawValue)
    }
}
