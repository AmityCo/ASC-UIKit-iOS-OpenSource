//
//  BottomSheetItemView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/20/24.
//

import SwiftUI

enum IconBackground {
    case none
    case circular
}

struct BottomSheetItemView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController
    private let icon: ImageResource?
    private let text: String
    private let iconBackground: IconBackground
    private let iconSize: CGSize
    private let isDestructive: Bool
    private let tintColor: UIColor?
    
    init(icon: ImageResource?,
         text: String,
         iconBackground: IconBackground = .none,
         iconSize: CGSize = CGSize(width: 20, height: 24),
         tintColor: UIColor? = nil,
         isDestructive: Bool = false) {
        self.icon = icon
        self.text = text
        self.iconSize = iconSize
        self.isDestructive = isDestructive
        self.tintColor = tintColor
        self.iconBackground = iconBackground
    }
    
    var body: some View {
        getItemView(icon, text: text, isDestructive: isDestructive)
    }
    
    var foregroundTintColor: UIColor {
        return tintColor ?? (isDestructive ? viewConfig.theme.alertColor : viewConfig.theme.baseColor)
    }
    
    private func getItemView(_ icon: ImageResource?, text: String, isDestructive: Bool = false) -> some View {
        HStack(spacing: 12) {
            if let icon {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize.width, height: iconSize.height)
                    .foregroundColor(Color(foregroundTintColor))
                    .padding(iconBackground == .circular ? 6 : 0)
                    .background(iconBackground == .circular ? Color(viewConfig.theme.backgroundShade1Color).clipped().clipShape(Circle()) : nil)
            }
            
            Text(text)
                .applyTextStyle(.bodyBold(Color(foregroundTintColor)))
            
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
    }
}
