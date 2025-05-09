//
//  AmityButtonStyle.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 28/4/25.
//

import SwiftUI

/// Supports PrimaryStyle Button as per Figma.
struct AmityPrimaryButtonStyle: ButtonStyle {
    
    let viewConfig: AmityViewConfigController
    let isDisabled: Bool
    
    init(viewConfig: AmityViewConfigController, isDisabled: Bool = false) {
        self.viewConfig = viewConfig
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            
            configuration.label
                .modifier(AmityTextViewModifier(textStyle: .bodyBold( configuration.isPressed ? Color.white.opacity(0.5) : Color.white)))
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
            
            Spacer()
        }
        .background(Color(isDisabled ? viewConfig.theme.primaryColor.blend(.shade3) : viewConfig.theme.primaryColor))
        .disabled(isDisabled)
        .cornerRadius(8)
    }
}

