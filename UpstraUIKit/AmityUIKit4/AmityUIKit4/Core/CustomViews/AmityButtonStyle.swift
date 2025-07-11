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
    
    private let viewConfig: AmityViewConfigController
    private let isDisabled: Bool
    private let vPadding: CGFloat
    private let hPadding: CGFloat
    private let size: ButtonSize
    private let radius: CGFloat
    
    init(viewConfig: AmityViewConfigController, size: ButtonSize = .expanded, isDisabled: Bool = false, hPadding: CGFloat = 16, vPadding: CGFloat = 12, radius: CGFloat = 8) {
        self.viewConfig = viewConfig
        self.isDisabled = isDisabled
        self.size = size
        self.hPadding = hPadding
        self.vPadding = vPadding
        self.radius = radius
    }
    
    func makeBody(configuration: Configuration) -> some View {
        buttonContent(configuration: configuration)
            .background(Color(isDisabled ? viewConfig.theme.primaryColor.blend(.shade3) : viewConfig.theme.primaryColor))
            .disabled(isDisabled)
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
        borderColor: UIColor? = nil,
    ) {
        self.viewConfig = viewConfig
        self.vPadding = vPadding
        self.hPadding = hPadding
        self.size = size
        self.radius = radius
        self.borderColor = borderColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        buttonContent(configuration: configuration)
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Color(borderColor ?? viewConfig.theme.baseColorShade3), lineWidth: 1)
            )
            .cornerRadius(radius)
    }
    
    @ViewBuilder
    func buttonContent(configuration: Configuration) -> some View {
        switch size {
        case .compact:
            configuration.label
                .modifier(AmityTextViewModifier(textStyle: .bodyBold( configuration.isPressed ? Color(viewConfig.theme.baseColor.withAlphaComponent(0.3)) : Color(viewConfig.theme.baseColor))))
                .padding(.vertical, vPadding)
                .padding(.horizontal, hPadding)
                
        case .expanded:
            HStack {
                Spacer()
                
                configuration.label
                    .modifier(AmityTextViewModifier(textStyle: .bodyBold( configuration.isPressed ? Color(viewConfig.theme.baseColor.withAlphaComponent(0.3)) : Color(viewConfig.theme.baseColor))))
                    .padding(.vertical, vPadding)
                    .padding(.horizontal, hPadding)
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
    }
}
