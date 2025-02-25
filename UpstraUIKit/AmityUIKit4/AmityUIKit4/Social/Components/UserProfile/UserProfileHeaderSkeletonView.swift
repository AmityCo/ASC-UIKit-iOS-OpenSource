//
//  UserProfileHeaderSkeletonView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/30/24.
//
import SwiftUI

struct UserProfileHeaderSkeletonView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade3))
                    .shimmering(gradient: shimmerGradient)
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade3))
                    .shimmering(gradient: shimmerGradient)
                    .frame(width: 140, height: 13)
                    .clipShape(RoundedCorner())
                
                Spacer()
            }
            
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade3))
                .shimmering(gradient: shimmerGradient)
                .frame(width: 230, height: 8)
                .clipShape(RoundedCorner())
            
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade3))
                .shimmering(gradient: shimmerGradient)
                .frame(width: 250, height: 8)
                .clipShape(RoundedCorner())
            
            HStack(spacing: 10) {
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade3))
                    .shimmering(gradient: shimmerGradient)
                    .frame(width: 40, height: 13)
                    .clipShape(RoundedCorner())
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade3))
                    .shimmering(gradient: shimmerGradient)
                    .frame(width: 40, height: 13)
                    .clipShape(RoundedCorner())
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }
}
