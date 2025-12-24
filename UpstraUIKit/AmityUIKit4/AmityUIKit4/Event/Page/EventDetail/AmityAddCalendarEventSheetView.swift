//
//  AmityAddCalendarEventSheetView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 13/11/25.
//

import SwiftUI

struct AmityAddCalendarEventSheetView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    let action: DefaultTapAction?
    
    var body: some View {
        VStack(spacing: 0) {

            Image(AmityIcon.eventAddToCalendarIcon.imageResource)
                .resizable()
                .frame(width: 105, height: 102)
                .padding(.top, 32)

            Text(AmityLocalizedStringSet.Social.addCalendarSheetTitle.localizedString)
                .applyTextStyle(.headline(Color(viewConfig.theme.baseColor)))
                .padding(.bottom, 8)
                .padding(.top, 32)

            Text(AmityLocalizedStringSet.Social.addCalendarSheetDescription.localizedString)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade1)))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
                .padding(.top, 16)

            Button {
                action?()
            } label: {
                HStack {
                    Image(AmityIcon.addToCalendarButtonIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)

                    Text(AmityLocalizedStringSet.Social.addCalendarSheetAddButton.localizedString)
                }
            }
            .buttonStyle(AmityPrimaryButtonStyle(viewConfig: viewConfig))
            .padding(.vertical, 16)
            .padding(.horizontal, 16)

        }
    }
}
