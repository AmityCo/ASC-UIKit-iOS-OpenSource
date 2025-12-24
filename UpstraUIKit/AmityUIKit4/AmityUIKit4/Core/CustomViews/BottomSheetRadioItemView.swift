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
            
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 2.0)
                    .fill(.gray)
                    .frame(width: 16, height: 16)
                    .opacity(isSelected ? 0 : 1)
                
                Image(AmityIcon.pollRadioIcon.imageResource)
                    .frame(width: 22, height: 22)
                    .opacity(isSelected ? 1 : 0)
            }
        }
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
    }
}
