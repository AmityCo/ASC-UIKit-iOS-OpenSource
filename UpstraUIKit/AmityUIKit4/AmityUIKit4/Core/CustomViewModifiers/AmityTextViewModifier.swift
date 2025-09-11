//
//  AmityText.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/22/24.
//

import SwiftUI

public enum AmityTextStyle {
    case display(Color)
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
    
    func getUIFont() -> UIFont {
        UIFont.systemFont(ofSize: getStyle().fontSize, weight: getStyle().weight.convertToUIFontWeight())
    }
    
    func getStyle() -> (fontSize: CGFloat, weight: Font.Weight, color: Color) {
        switch self {
        case .display(let color):
            return (fontSize: 32, weight: .bold, color: color)
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
    
    func withColor(_ color: Color) -> AmityTextStyle {
        switch self {
        case .display(_):
            return .display(color)
        case .headline(_):
            return .headline(color)
        case .titleBold(_):
            return .titleBold(color)
        case .title(_):
            return .title(color)
        case .bodyBold(_):
            return .bodyBold(color)
        case .body(_):
            return .body(color)
        case .captionBold(_):
            return .captionBold(color)
        case .caption(_):
            return .caption(color)
        case .captionSmall(_):
            return .captionSmall(color)
        case .custom(let size, let weight, _):
            return .custom(size, weight, color)
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

extension TextEditor {
    func applyTextStyle(_ style: AmityTextStyle) -> some View {
        return self.modifier(AmityTextViewModifier(textStyle: style))
    }
}

extension Font.Weight {
    func convertToUIFontWeight() -> UIFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
}
