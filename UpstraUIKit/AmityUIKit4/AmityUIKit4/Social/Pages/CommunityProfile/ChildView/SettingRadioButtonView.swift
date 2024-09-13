//
//  SettingRadioButtonView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/23/24.
//

import SwiftUI

struct SettingRadioButtonView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    private let isSelected: Bool
    private let text: String
    
    init(isSelected: Bool, text: String) {
        self.isSelected = isSelected
        self.text = text
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Color(viewConfig.theme.baseColor))
            
            Spacer()
            
            Circle()
                .stroke(lineWidth: 1.0)
                .fill(.gray)
                .overlay(
                    Circle()
                        .fill(Color(viewConfig.theme.primaryColor))
                        .overlay(
                            Circle()
                                .fill(.white)
                                .frame(width: 8, height: 8)
                        )
                        .isHidden(!isSelected)
                )
                .frame(width: 18, height: 18)
        }
        .contentShape(Rectangle())
    }
}
