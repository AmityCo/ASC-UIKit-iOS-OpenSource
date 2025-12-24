//
//  AmityButtonStyle.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 28/4/25.
//

import SwiftUI

enum ButtonSize {
    // Takes required width only with padding
    case compact
    
    // Takes full width of the screen
    case expanded
}

/// Supports PrimaryStyle Button as per Figma.
struct AmityPrimaryButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) var isEnabled
    
    private let viewConfig: AmityViewConfigController
    private let vPadding: CGFloat
    private let hPadding: CGFloat
    private let size: ButtonSize
    private let radius: CGFloat
    private let backgroundColor: UIColor?
    
    init(viewConfig: AmityViewConfigController, size: ButtonSize = .expanded, hPadding: CGFloat = 16, vPadding: CGFloat = 12, radius: CGFloat = 8, backgroundColor: UIColor? = nil) {
        self.viewConfig = viewConfig
        self.size = size
        self.hPadding = hPadding
        self.vPadding = vPadding
        self.radius = radius
        self.backgroundColor = backgroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let enabledStateColor = backgroundColor ?? viewConfig.theme.primaryColor
        let disabledStateColor = backgroundColor?.withAlphaComponent(0.3) ?? viewConfig.theme.primaryColor.blend(.shade3)
        
        buttonContent(configuration: configuration)
            .background(Color(isEnabled ? enabledStateColor : disabledStateColor))
            .cornerRadius(radius)
    }
    
    @ViewBuilder
    func buttonContent(configuration: Configuration) -> some View {
        switch size {
        case .compact:
            configuration.label
                .modifier(AmityTextViewModifier(textStyle: .bodyBold( configuration.isPressed ? Color.white.opacity(0.5) : Color.white)))
                .padding(.vertical, vPadding)
                .padding(.horizontal, hPadding)
        case .expanded:
            HStack {
                Spacer()
                
                configuration.label
                    .modifier(AmityTextViewModifier(textStyle: .bodyBold( configuration.isPressed ? Color.white.opacity(0.5) : Color.white)))
                    .padding(.vertical, vPadding)
                    .padding(.horizontal, hPadding)
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
    }
}

// Supports Line Style buttons
struct AmityLineButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) var isEnabled
    
    private let viewConfig: AmityViewConfigController
    private let vPadding: CGFloat
    private let hPadding: CGFloat
    private let size: ButtonSize
    private let radius: CGFloat
    private let borderColor: UIColor?
    
    init(
        viewConfig: AmityViewConfigController,
        size: ButtonSize = .expanded,
        hPadding: CGFloat = 16,
        vPadding: CGFloat = 12,
        radius: CGFloat = 8,
        borderColor: UIColor? = nil
    ) {
        self.viewConfig = viewConfig
        self.vPadding = vPadding
        self.hPadding = hPadding
        self.size = size
        self.radius = radius
        self.borderColor = borderColor
    }
    
    var borderColorState: Color {
        let enabledState = Color(borderColor ?? viewConfig.theme.baseColorShade3)
        let disabledState = enabledState.opacity(0.6)
        return isEnabled ? enabledState : disabledState
    }
    
    func contentColorState(isPressed: Bool) -> Color {
        let enabledState = isPressed ? Color(viewConfig.theme.baseColor.withAlphaComponent(0.3)) : Color(viewConfig.theme.baseColor)
        let disabledState = enabledState.opacity(0.6)
        return isEnabled ? enabledState : disabledState
    }
    
    func makeBody(configuration: Configuration) -> some View {
        buttonContent(configuration: configuration)
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(borderColorState, lineWidth: 1)
            )
            .cornerRadius(radius)
    }
    
    @ViewBuilder
    func buttonContent(configuration: Configuration) -> some View {
        switch size {
        case .compact:
            configuration.label
                .modifier(AmityTextViewModifier(textStyle: .bodyBold(contentColorState(isPressed: configuration.isPressed))))
                .padding(.vertical, vPadding)
                .padding(.horizontal, hPadding)
            
        case .expanded:
            HStack {
                Spacer()
                
                configuration.label
                    .modifier(AmityTextViewModifier(textStyle: .bodyBold(contentColorState(isPressed: configuration.isPressed))))
                    .padding(.vertical, vPadding)
                    .padding(.horizontal, hPadding)
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
    }
}

/// Supports dropdown Button as per Figma.
struct AmityDropDownButtonStyle: ButtonStyle {
    
    private let viewConfig: AmityViewConfigController
    private let isDisabled: Bool
    private let vPadding: CGFloat
    private let hPadding: CGFloat
    private let size: ButtonSize
    private let radius: CGFloat
    
    init(viewConfig: AmityViewConfigController, size: ButtonSize = .expanded, isDisabled: Bool = false, hPadding: CGFloat = 12, vPadding: CGFloat = 12, radius: CGFloat = 8) {
        self.viewConfig = viewConfig
        self.isDisabled = isDisabled
        self.size = size
        self.hPadding = hPadding
        self.vPadding = vPadding
        self.radius = radius
    }
    
    func makeBody(configuration: Configuration) -> some View {
        buttonContent(configuration: configuration)
            .background(Color(isDisabled ? viewConfig.theme.baseColorShade4.blend(.shade3) : viewConfig.theme.baseColorShade4))
            .disabled(isDisabled)
            .cornerRadius(radius)
    }
    
    @ViewBuilder
    func buttonContent(configuration: Configuration) -> some View {
        let textColor = Color(viewConfig.theme.baseColor)
        
        switch size {
        case .compact:
            HStack {
                configuration.label
                    .modifier(AmityTextViewModifier(textStyle: .body( configuration.isPressed ? textColor.opacity(0.5) : textColor)))
                
                Image(AmityIcon.downArrowIcon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                    .padding(.leading, 12)
            }
            .padding(.vertical, vPadding)
            .padding(.horizontal, hPadding)
            .contentShape(Rectangle())

        case .expanded:
            HStack {
                configuration.label
                    .modifier(AmityTextViewModifier(textStyle: .body( configuration.isPressed ? textColor.opacity(0.5) : textColor)))
                
                Spacer()
                
                Image(AmityIcon.downArrowIcon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                    
            }
            .padding(.vertical, vPadding)
            .padding(.horizontal, hPadding)
            .frame(minHeight: 40)
            .contentShape(Rectangle())
        }
    }
}

/// Supports selection Button as per Figma.
struct AmitySelectionButtonStyle: ButtonStyle {
    
    private let viewConfig: AmityViewConfigController
    private let isDisabled: Bool
    private let vPadding: CGFloat
    private let hPadding: CGFloat
    private let size: ButtonSize
    private let radius: CGFloat
    private let alignment: TextAlignment
    
    init(
        viewConfig: AmityViewConfigController,
        size: ButtonSize = .expanded,
        alignment: TextAlignment = .center,
        isDisabled: Bool = false,
        hPadding: CGFloat = 12,
        vPadding: CGFloat = 12,
        radius: CGFloat = 8
    ) {
        self.viewConfig = viewConfig
        self.isDisabled = isDisabled
        self.size = size
        self.hPadding = hPadding
        self.vPadding = vPadding
        self.radius = radius
        self.alignment = alignment
    }
    
    func makeBody(configuration: Configuration) -> some View {
        buttonContent(configuration: configuration)
            .background(Color(isDisabled ? viewConfig.theme.baseColorShade4.blend(.shade3) : viewConfig.theme.baseColorShade4))
            .disabled(isDisabled)
            .cornerRadius(radius)
    }
    
    @ViewBuilder
    func buttonContent(configuration: Configuration) -> some View {
        let textColor = Color(viewConfig.theme.baseColor)
        
        switch size {
        case .compact:
            configuration.label
                .modifier(AmityTextViewModifier(textStyle: .body( configuration.isPressed ? textColor.opacity(0.5) : textColor)))
                .padding(.vertical, vPadding)
                .padding(.horizontal, hPadding)
        case .expanded:
            HStack {
                if alignment == .center || alignment == .trailing {
                    Spacer()
                }
                
                configuration.label
                    .modifier(AmityTextViewModifier(textStyle: .body( configuration.isPressed ? textColor.opacity(0.5) : textColor)))
                
                if alignment == .center || alignment == .leading {
                    Spacer()
                }
            }
            .padding(.vertical, vPadding)
            .padding(.horizontal, hPadding)
            .frame(minHeight: 40)
            .contentShape(Rectangle())
        }
    }
}
