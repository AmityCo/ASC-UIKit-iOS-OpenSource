//
//  AmityAdInfoView.swift
//  AmityUIKit4
//
//  Created by Nishan on 1/7/2567 BE.
//

import SwiftUI

struct AmityAdInfoView: View {
    
    let advertiserName: String
    
    @EnvironmentObject var viewConfig: AmityViewConfigController

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                
                BottomSheetDragIndicator()
                    .foregroundColor(Color(viewConfig.defaultLightTheme.baseColorShade3))
                
                Spacer()
            }
            
            Text(AmityLocalizedStringSet.General.adAboutTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                .offset(y: -1)
            
            Text(AmityLocalizedStringSet.General.adWhyTitle.localizedString)
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                .padding(.top, 24)
            
            HStack(alignment: .top) {
                Image(AmityIcon.infoIcon.imageResource)
                    .padding(.top, 2)
                
                Text(AmityLocalizedStringSet.General.adWhyDescription.localizedString)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                
                Spacer()
            }
            .padding()
            .background(Color(viewConfig.theme.baseColorShade4))
            
            Text(AmityLocalizedStringSet.General.adAboutAdvertiser.localizedString)
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                .padding(.top, 24)
            
            HStack(alignment: .top) {
                Image(AmityIcon.infoIcon.imageResource)
                    .padding(.top, 2)

                Text(AmityLocalizedStringSet.General.adAdvertiserName.localized(arguments: advertiserName))
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))

                Spacer()
            }
            .padding()
            .background(Color(viewConfig.theme.baseColorShade4))
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .background(Color(viewConfig.theme.backgroundColor))
    }
}

#if DEBUG
#Preview {
    AmityAdInfoView(advertiserName: "Nishan")
        .environmentObject(AmityViewConfigController(pageId: nil, componentId: .postContentComponent))
}
#endif
