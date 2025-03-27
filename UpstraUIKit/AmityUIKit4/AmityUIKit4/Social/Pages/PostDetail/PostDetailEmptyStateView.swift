//
//  PostDetailEmptyStateView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 18/3/25.
//

import SwiftUI

struct PostDetailEmptyStateView: View {
    
    var action: (() -> Void)?
    
    @StateObject private var viewConfig: AmityViewConfigController = AmityViewConfigController(pageId: nil)
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper

    var body: some View {
        VStack(spacing: 0) {
            
            Spacer()
            
            Image(AmityIcon.emptyStateExplore.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 40)
                .foregroundColor(Color(viewConfig.theme.baseColorShade2))
            
            Text(AmityLocalizedStringSet.Social.postDetailDeletedPostTitle.localizedString)
                .applyTextStyle(.headline(Color(viewConfig.theme.baseColorShade3)))
                .padding(.top, 16)
            
            Text(AmityLocalizedStringSet.Social.postDetailDeletedPostMessage.localizedString)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade3)))
                .padding(.top, 8)

            Button {
                if let action {
                    action()
                } else {
                    host.controller?.navigationController?.popViewController(animated: true)
                }
            } label: {
                Text(AmityLocalizedStringSet.Social.postDetailDeletedPostButtonTitle.localizedString)
                    .applyTextStyle(.bodyBold(Color(.white)))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(viewConfig.theme.primaryColor))
                    .cornerRadius(8, corners: .allCorners)
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            
            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(viewConfig.theme.backgroundColor))
    }
}

#Preview {
    PostDetailEmptyStateView()
}
