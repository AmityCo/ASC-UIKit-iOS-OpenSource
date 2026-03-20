//
//  AmityProductTagListHeaderElement.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/22/26.
//

import SwiftUI

/// Header element for the ProductTagListComponent (v2).
/// Displays context-aware title based on render mode.
///
/// Element ID: `product_tag_list_header`
struct AmityProductTagListHeaderElement: AmityElementView {

    var pageId: PageId?
    var componentId: ComponentId?

    var id: ElementId {
        return .productTagListHeader
    }

    /// Context mode for determining header text (v2)
    let renderMode: ProductTagListRenderMode

    /// Optional close action for livestream mode
    let onClose: (() -> Void)?

    @EnvironmentObject var viewConfig: AmityViewConfigController

    var body: some View {
        if renderMode == .livestream {
            ZStack {
                Text(headerText)
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                    .accessibilityAddTraits(.isHeader)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack {
                    Spacer()
                    Button(action: { onClose?() }) {
                        Image(AmityIcon.closeIcon.getImageResource())
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                    }
                }
            }
        } else {
            Text(headerText)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                .accessibilityAddTraits(.isHeader)
        }
    }

    /// Returns context-aware header text based on renderMode (REQ-001)
    private var headerText: String {
        // Check for custom text from config first
        let customKey: String
        switch renderMode {
        case .post:
            customKey = "text_post"
        case .livestream:
            customKey = "text_livestream"
        case .image:
            customKey = "text_image"
        case .video:
            customKey = "text_video"
        }
        if let customText = viewConfig.getConfig(elementId: id, key: customKey, of: String.self) {
            return customText
        }

        // Fallback to default text based on render mode
        switch renderMode {
        case .post:
            return "Products tagged in this post"
        case .livestream:
            return "Products tagged"
        case .image:
            return "Products tagged in this photo"
        case .video:
            return "Products tagged in this video"
        }
    }
}
