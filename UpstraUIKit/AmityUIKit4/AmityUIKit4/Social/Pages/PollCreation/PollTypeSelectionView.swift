//
//  PollTypeSelectionView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 18/7/25.
//

import SwiftUI

struct PollTypeSelectionView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @State private var selectedPollType: AmityPollType = .text
    var onNextAction: (AmityPollType) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            
            Text("Choose poll type")
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                .padding(.top, 24)
                .padding(.bottom, 12)
            
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
                .padding(.bottom, 16)
            
            HStack(spacing: 12) {
                OptionView(type: .text, isSelected: selectedPollType == .text) {
                    selectedPollType = .text
                }

                OptionView(type: .image, isSelected: selectedPollType == .image) {
                    selectedPollType = .image
                }
            }
            .padding(.horizontal, 16)

            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
                .padding(.vertical, 16)
            
            Button("Next") {
                onNextAction(selectedPollType)
            }
            .buttonStyle(AmityPrimaryButtonStyle(viewConfig: viewConfig))
            .padding(.horizontal, 16)
            .padding(.bottom, 64)
        }
    }
    
    struct OptionView : View {
        
        private let optionWidth: Double = UIScreen.main.bounds.width > 320 ? 165 : 112
        
        @EnvironmentObject private var viewConfig: AmityViewConfigController
        
        let type: AmityPollType
        let isSelected: Bool
        let action: () -> Void
        
        var icon: AmityIcon {
            switch type {
            case .image:
                return isSelected ? AmityIcon.imagePollOptionSelected : AmityIcon.imagePollOption
            case .text:
                return isSelected ? AmityIcon.textPollOptionSelected : AmityIcon.textPollOption
            }
        }
        
        var body: some View {
            Button {
                action()
            } label: {
                VStack {
                    VStack {
                        Image(icon.imageResource)
                            .resizable()
                            .foregroundColor(Color(viewConfig.theme.secondaryColor.blend(.shade4)))
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .padding(.vertical, style: .spacing4XL)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(viewConfig.theme.secondaryColor.blend(.shade4)))
                    
                    Text(type == .text ? "Text-only poll" : "Image poll")
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                        .padding(.horizontal, 12)
                        .padding(.top, style: .spacingLG)
                        .padding(.bottom, style: .spacingXL)
                }
                .frame(maxWidth: 200)
                .background(Color(viewConfig.theme.backgroundColor))
                .clipped()
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .border(radius: 8, borderColor: isSelected ? Color(viewConfig.theme.primaryColor) : Color(viewConfig.theme.secondaryColor.blend(.shade4)), borderWidth: 2)
        }
    }
}
