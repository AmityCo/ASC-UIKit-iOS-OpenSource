//
//  ExploreComponentSkeletonView.swift
//  AmityUIKit4
//
//  Created by Nishan on 29/8/2567 BE.
//

import SwiftUI

struct ExploreComponentSkeletonView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading) {
                ExploreCategorySkeletonView()
                
                ExploreRecommendedSkeletonView()
                
                ExploreTrendingSkeletonView()
            }
        }
    }
}

struct SkeletonRectangle: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    let height: CGFloat
    let width: CGFloat
    let cornerRadius: CGFloat
    
    init(height: CGFloat = 12, width: CGFloat = 200, cornerRadius: CGFloat = 12) {
        self.height = height
        self.width = width
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .fill(Color(viewConfig.theme.baseColorShade4))
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius, corners: .allCorners)
    }
}


#if DEBUG
#Preview {
    ExploreComponentSkeletonView()
        .environmentObject(AmityViewConfigController(pageId: .socialHomePage))
}
#endif

struct ExploreCategorySkeletonView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    let count: Int = 7
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(0..<count, id: \.self) { item in
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(width: 90, height: 36)
                    }
                }
                .padding(.vertical, 8)
                .padding(.leading)
            }
        }
    }
}

struct ExploreRecommendedSkeletonView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    let count = 3
    
    var body: some View {
        VStack(alignment: .leading) {
            // Divider
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 8)
            
            // Recommended
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<count, id: \.self) { index in
                        VStack(alignment: .leading) {
                            SkeletonRectangle(height: 130, width: 280, cornerRadius: 0)
                            
                            VStack(alignment: .leading) {
                                SkeletonRectangle(width: 83)
                                    .padding(.bottom, 8)
                                SkeletonRectangle(width: 140)
                                SkeletonRectangle(width: 180)
                            }
                            .padding()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
                        )
                    }
                }
                .padding(.leading)
                .padding(.vertical, 12)
            }
        }
    }
}

struct ExploreTrendingSkeletonView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    let count = 5
    
    var body: some View {
        VStack(alignment: .leading) {
            // Divider
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 8)
            
            // Content
            VStack(alignment: .leading, spacing: 0) {
                
                SkeletonRectangle(width: 150)
                    .padding(.vertical, 12)
                
                ForEach(0..<count, id: \.self) { index in
                    HStack {
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(width: 80, height: 80)
                            .cornerRadius(8, corners: .allCorners)
                        
                        VStack(alignment: .leading) {
                            SkeletonRectangle(width: 200)
                            SkeletonRectangle(width: 100)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 12)
                        .opacity(index == count - 1 ? 0 : 1) // Hide last divider
                }
            }
            .padding(.horizontal)
        }
    }
}
