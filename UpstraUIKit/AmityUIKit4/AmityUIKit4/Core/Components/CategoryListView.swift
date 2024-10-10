//
//  CategoryListView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/8/24.
//

import SwiftUI
import AmitySDK

struct CategoryListView: View {
    
    let community: AmityCommunityModel
    let shownCategories: [String]
    let notShownCategories: Int
    
    init(community: AmityCommunityModel) {
        self.community = community
        
        let maxCategoriesToShow = 2
        let categories = community.categories
        self.shownCategories = Array(categories.prefix(maxCategoriesToShow))
        
        let totalCount = community.categories.count
        let remainingCategories = totalCount - maxCategoriesToShow
        self.notShownCategories = max(remainingCategories, 0)
    }
    
    var body: some View {
        HStack {
            ForEach(shownCategories, id: \.self) { item in
                SmallCommunityCategoryLabel(title: item)
            }
            
            if notShownCategories > 0 {
                SmallCommunityCategoryLabel(title: "+ \(notShownCategories)")
                    .layoutPriority(1)
            }
        }
        .accessibilityLabel(AccessibilityID.Social.Explore.communityCategories)
    }
}

struct SmallCommunityCategoryLabel: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    let title: String
    
    var body: some View {
        Text(title)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .foregroundColor(Color(viewConfig.theme.baseColor))
            .lineLimit(1)
            .background(Color(viewConfig.theme.baseColorShade4))
            .clipShape(Capsule())
    }
}
