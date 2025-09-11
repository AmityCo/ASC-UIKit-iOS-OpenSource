//
//  BottomSheetRadioItemView.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 23/7/2568 BE.
//

import SwiftUI

struct BottomSheetRadioItemView: View {
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
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
            
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
                        .visibleWhen(isSelected)
                )
                .frame(width: 18, height: 18)
        }
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
    }
}
