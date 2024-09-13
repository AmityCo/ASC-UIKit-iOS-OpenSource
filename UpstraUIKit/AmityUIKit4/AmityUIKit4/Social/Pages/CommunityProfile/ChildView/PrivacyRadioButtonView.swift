//
//  PrivacyRadioButtonView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/7/24.
//

import SwiftUI

struct PrivacyRadioButtonView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    private let isSelected: Bool
    private let icon: ImageResource
    private let title: String
    private let description: String
    
    init(isSelected: Bool, icon: ImageResource, title: String, description: String) {
        self.isSelected = isSelected
        self.icon = icon
        self.title = title
        self.description = description
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .clipShape(Circle())
                    .overlay (
                        Image(icon)
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 24, height:  20)
                    )
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .font(.system(size: 15, weight: .semibold))
                    
                    Text(description)
                        .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                        .font(.system(size: 13))
                }
                
                Spacer()
                
                Color
                    .clear
                    .overlay(
                        Circle()
                            .stroke(lineWidth: 2.0)
                            .fill(isSelected ? .blue : .gray)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 9, height: 9)
                                    .isHidden(!isSelected)
                            )
                            .padding([.bottom, .leading], 15)
                            .padding(.trailing, 32)
                    )
                    .frame(width: 24, height: 24)
                
            }
            
            Spacer()
        }
    }
}
