//
//  AmityProductTagSelectionItemElement.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/14/26.
//

import SwiftUI
import AmitySDK

struct AmityProductTagSelectionItemElement: AmityElementView {

    var pageId: PageId?
    var componentId: ComponentId?

    var id: ElementId {
        return .productTagSelectionItem
    }

    @EnvironmentObject var viewConfig: AmityViewConfigController

    let product: AmityProduct
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    var isLivestream: Bool = false

    private var isAlreadyTagged: Bool {
        isDisabled && isSelected
    }

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(placeholderView: {
                ZStack {
                    Color(viewConfig.theme.baseColorShade4)
                    Image(AmityIcon.LiveStream.productTagImagePlaceholderIcon.imageResource)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                        .frame(width: 28, height: 28)
                }
            }, url: URL(string: product.thumbnailUrl ?? ""), contentMode: .fill)
            .frame(width: 80, height: 80)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .bottomLeft]))

            VStack(alignment: .leading, spacing: 0) {
                Text(product.productName)
                    .applyTextStyle(.bodyBold(Color(isAlreadyTagged ? viewConfig.theme.baseColorShade4 : viewConfig.theme.baseColor)))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isAlreadyTagged {
                    Text("Already tagged")
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                        .lineLimit(1)
                        .padding(.top, 8)
                        .isHidden(isLivestream)
                }
            }

            ZStack {
                Circle()
                    .stroke(lineWidth: 2.0)
                    .fill(isDisabled && !isSelected ? Color(viewConfig.theme.baseColorShade4) : Color(viewConfig.theme.baseColorShade3))
                    .frame(width: 16, height: 16)
                    .isHidden(isSelected)

                Image(AmityIcon.checkboxIcon.getImageResource())
                    .renderingMode(.template)
                    .foregroundColor(Color(isAlreadyTagged ? viewConfig.theme.primaryColor.blend(.shade2) : viewConfig.theme.primaryColor))
                    .frame(width: 22, height: 22)
                    .isHidden(!isSelected)
                    .offset(x: 3)
            }
            .padding(.trailing, 16)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isDisabled {
                onTap()
            }
        }
    }
}
