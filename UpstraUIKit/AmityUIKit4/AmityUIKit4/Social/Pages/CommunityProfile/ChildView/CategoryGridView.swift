//
//  CategoryGridView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/8/24.
//

import SwiftUI

struct CategoryGridView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @Binding private var categories: [AmityCommunityCategoryModel]
    
    init(categories: Binding<[AmityCommunityCategoryModel]>) {
        self._categories = categories
    }
    
    var body: some View {
        FlexibleView(data: categories, spacing: 8, alignment: .leading) { category in
            HStack(spacing: 5) {
                AsyncImage(placeholder: AmityIcon.defaultCommunity.getImageResource(), url: URL(string: category.avatarURL))
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
                
                Text(category.name)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .frame(maxWidth: UIScreen.main.bounds.width - 130)
                
                Image(AmityIcon.closeIcon.getImageResource())
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                    .frame(width: 24, height: 20)
            }
            .padding(.all, 4)
            .overlay(
                RoundedCorner()
                    .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
            )
            .clipShape(Rectangle())
            .onTapGesture {
                guard let index = categories.firstIndex(of: category) else { return }
                categories.remove(at: index)
            }
        }
    }
}
