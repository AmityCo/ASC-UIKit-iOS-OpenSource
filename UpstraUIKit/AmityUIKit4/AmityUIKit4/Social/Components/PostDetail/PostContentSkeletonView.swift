//
//  PostContentSkeletonView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/29/24.
//

import SwiftUI

let shimmerGradient = Gradient(colors: [.black.opacity(0.2),
                                                .black.opacity(0.4),
                                                .black.opacity(0.2)])

struct PostContentSkeletonView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade3))
                    .frame(width: 50, height: 50)
                    .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .shimmering(gradient: shimmerGradient)
                
                VStack(alignment: .leading, spacing: 12) {
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade3))
                        .frame(width: 120, height: 10)
                        .clipShape(RoundedCorner())
                        .shimmering(gradient: shimmerGradient)
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade3))
                        .frame(width: 80, height: 10)
                        .clipShape(RoundedCorner())
                        .shimmering(gradient: shimmerGradient)
                }
                
                Spacer()
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 0, trailing: 12))
            
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade3))
                        .frame(width: 250, height: 10)
                        .clipShape(RoundedCorner())
                        .shimmering(gradient: shimmerGradient)
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade3))
                        .frame(width: 300, height: 10)
                        .clipShape(RoundedCorner())
                        .shimmering(gradient: shimmerGradient)
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade3))
                        .frame(width: 190, height: 10)
                        .clipShape(RoundedCorner())
                        .shimmering(gradient: shimmerGradient)
                }
                
                Spacer()
            }
            .padding(EdgeInsets(top: 8, leading: 20, bottom: 80, trailing: 12))
            
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 8)
            
            Spacer()
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }
}

#if DEBUG
#Preview {
    PostContentSkeletonView()
        .environmentObject(AmityViewConfigController(pageId: .communityProfilePage))
}
#endif
