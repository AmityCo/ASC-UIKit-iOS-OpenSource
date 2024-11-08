//
//  AmityText.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/22/24.
//

import SwiftUI

enum AmityTextStyle {
    case headline(Color)
    case titleBold(Color)
    case title(Color)
    case bodyBold(Color)
    case body(Color)
    case captionBold(Color)
    case caption(Color)
    case captionSmall(Color)
    case custom(CGFloat, Font.Weight, Color)
    
    func getFont() -> Font {
        .system(size: getStyle().fontSize, weight: getStyle().weight)
    }
    
    func getStyle() -> (fontSize: CGFloat, weight: Font.Weight, color: Color) {
        switch self {
        case .headline(let color):
            return (fontSize: 20, weight: .bold, color: color)
        case .titleBold(let color):
            return (fontSize: 17, weight: .semibold, color: color)
        case .title(let color):
            return (fontSize: 17, weight: .regular, color: color)
        case .bodyBold(let color):
            return (fontSize: 15, weight: .semibold, color: color)
        case .body(let color):
            return (fontSize: 15, weight: .regular, color: color)
        case .captionBold(let color):
            return (fontSize: 13, weight: .semibold, color: color)
        case .caption(let color):
            return (fontSize: 13, weight: .regular, color: color)
        case .captionSmall(let color):
            return (fontSize: 10, weight: .regular, color: color)
        case .custom(let size, let weight, let color):
            return (fontSize: size, weight: weight, color: color)
        }
    }
}

struct AmityTextViewModifier: ViewModifier {
    let textStyle: AmityTextStyle
    
    init(textStyle: AmityTextStyle) {
        self.textStyle = textStyle
    }
    
    func body(content: Content) -> some View {
        let style = textStyle.getStyle()
        
        content
            .font(textStyle.getFont())
            .foregroundColor(style.color)
    }
}

extension Text {
    func applyTextStyle(_ style: AmityTextStyle) -> some View {
        return self.modifier(AmityTextViewModifier(textStyle: style))
    }
}

extension TextField {
    func applyTextStyle(_ style: AmityTextStyle) -> some View {
        return self.modifier(AmityTextViewModifier(textStyle: style))
    }
}
