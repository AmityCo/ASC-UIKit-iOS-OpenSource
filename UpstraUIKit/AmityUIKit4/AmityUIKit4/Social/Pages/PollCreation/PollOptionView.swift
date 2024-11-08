//
//  PollOptionView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 8/10/2567 BE.
//

import SwiftUI

// Expanded & Normal
struct PollOptionView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    let title: String
    let isSelected: Bool
    let allowMultiSelection: Bool
    let onSelection: () -> Void
    
    var body: some View {
        Button(action: {
            onSelection()
        }, label: {
            HStack {
                Text(title)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                    .padding(.leading, 12)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(lineWidth: 2.0)
                        .fill(.gray)
                        .frame(width: 16, height: 16)
                        .opacity(isSelected ? 0 : 1)
                    
                    Image(allowMultiSelection ? AmityIcon.checkboxIcon.imageResource : AmityIcon.pollRadioIcon.imageResource)
                        .frame(width: 22, height: 22)
                        .opacity(isSelected ? 1 : 0)
                }
                .padding(.trailing, 12)
            }
            .padding(.vertical, 12)
            .border(radius: 8, borderColor: Color(isSelected ? viewConfig.theme.primaryColor : viewConfig.theme.baseColorShade4 ), borderWidth: 1)
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    PollOptionView(title: "Succulents 🌵", isSelected: true, allowMultiSelection: true, onSelection: { })
        .environmentObject(AmityViewConfigController(pageId: .postDetailPage))
}
#endif
