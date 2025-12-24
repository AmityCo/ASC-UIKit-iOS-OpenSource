//
//  UserDisplayNameLabel.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 21/11/25.
//
import SwiftUI

// Global Element
struct UserDisplayNameLabel: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    let name: String
    let isBrand: Bool
    let spacing: CGFloat // spacing between title & brand badge, default is 4
    let size: CGSize  // size of the brand badge
    let style: AmityTextStyle?
    
    init(name: String,
         isBrand: Bool,
         textStyle: AmityTextStyle? = nil,
         size: CGSize = .init(width: 16, height: 16),
         spacing: CGFloat = 4,
    ) {
        self.name = name
        self.isBrand = isBrand
        self.spacing = spacing
        self.size = size
        self.style = textStyle
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(name)
                .applyTextStyle(style ?? .bodyBold(Color(viewConfig.theme.baseColor)))
                .lineLimit(1)
                .accessibilityIdentifier("user_display_name")
            
            if isBrand {
                Image(AmityIcon.brandBadge.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .padding(.leading, spacing)
                    .accessibilityIdentifier("brand_badge")
            }
        }
    }
}
