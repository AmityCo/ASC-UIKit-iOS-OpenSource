//
//  SkeletonStoryTabComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/3/25.
//

import SwiftUI

struct SkeletonStoryTabComponent: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController
    let radius: CGFloat
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<8, id: \.self) { _ in
                    VStack(spacing: 10) {
                        SkeletonRectangle(height: radius, width: radius, cornerRadius: 0)
                            .frame(width: radius, height: radius)
                            .clipShape(Circle())
                        
                        SkeletonRectangle(height: 10, width: radius, cornerRadius: 30)
                    }
                }
            }
        }
    }
}
