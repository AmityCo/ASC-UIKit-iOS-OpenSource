//
//  CommentSkeletonView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 7/8/24.
//

import Foundation
import SwiftUI

struct CommentSkeletonView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade3))
                    .frame(width: 32, height: 32, alignment: .topLeading)
                    .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                    .shimmering(gradient: shimmerGradient)
                
                VStack(alignment: .leading, spacing: 11) {
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade3))
                        .frame(width: 220, height: 68)
                        .shimmering(gradient: shimmerGradient)
                        .clipShape(RoundedCorner(radius: 12, corners: [.topRight, .bottomLeft, .bottomRight]))
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade3))
                        .frame(width: 165, height: 8)
                        .clipShape(RoundedCorner())
                        .shimmering(gradient: shimmerGradient)
                }
                
                
                Spacer()
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 0, trailing: 12))
            
            Spacer()
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }
}


struct TestSkeletonView: View {
    @StateObject var viewConfig = AmityViewConfigController(pageId: nil)
    
    var body: some View {
        CommentSkeletonView()
            .environmentObject(viewConfig)
    }
}

#if DEBUG
#Preview {
    TestSkeletonView()
}
#endif
