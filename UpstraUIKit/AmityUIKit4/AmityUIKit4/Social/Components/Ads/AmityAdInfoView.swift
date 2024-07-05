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
            
            Text("About this advertisement")
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .padding(.vertical, 8)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                .offset(y: -1)
            
            Text("Why this advertisement?")
                .font(.system(size: 15, weight: .semibold))
                .padding(.top, 24)
            
            HStack(alignment: .top) {
                Image(AmityIcon.infoIcon.imageResource)
                    .padding(.top, 2)
                
                Text("You're seeing this advertisement because it was displayed to all users in the system.")
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                    .font(.system(size: 13, weight: .regular))
                
                Spacer()
            }
            .padding()
            .background(Color(viewConfig.theme.baseColorShade4))
            
            Text("About this advertiser")
                .font(.system(size: 15, weight: .semibold))
                .padding(.top, 24)
            
            HStack(alignment: .top) {
                Image(AmityIcon.infoIcon.imageResource)
                    .padding(.top, 2)

                Text("Advertiser name: \(advertiserName)")
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                    .font(.system(size: 13, weight: .regular))

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

#Preview {
    AmityAdInfoView(advertiserName: "Nishan")
        .environmentObject(AmityViewConfigController(pageId: nil, componentId: .postContentComponent))
}
