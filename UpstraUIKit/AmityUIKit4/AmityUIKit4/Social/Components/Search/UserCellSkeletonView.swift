//
//  UserCellSkeletonView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/2/24.
//

import Foundation

import SwiftUI

struct UserCellSkeletonView: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade3))
                .frame(size: CGSize(width: 40, height: 40))
                .clipShape(Circle())
                .shimmering(gradient: shimmerGradient)
            
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade3))
                .frame(size: CGSize(width: 120, height: 8))
                .clipShape(RoundedCorner())
                .shimmering(gradient: shimmerGradient)
            
            Spacer()
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }
}
