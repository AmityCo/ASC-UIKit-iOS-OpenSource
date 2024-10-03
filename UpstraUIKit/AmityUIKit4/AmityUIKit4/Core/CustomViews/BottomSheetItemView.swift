//
//  BottomSheetItemView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/20/24.
//

import SwiftUI

struct BottomSheetItemView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController
    private let icon: ImageResource
    private let text: String
    private let isDestructive: Bool
    
    init(icon: ImageResource, text: String, isDestructive: Bool = false) {
        self.icon = icon
        self.text = text
        self.isDestructive = isDestructive
    }
    
    var body: some View {
        getItemView(icon, text: text, isDestructive: isDestructive)
    }
    
    private func getItemView(_ icon: ImageResource, text: String, isDestructive: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 24)
                .foregroundColor(isDestructive ? Color(viewConfig.theme.alertColor): Color(viewConfig.theme.baseColor))
            
            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isDestructive ? Color(viewConfig.theme.alertColor): Color(viewConfig.theme.baseColor))
            
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
    }
}
