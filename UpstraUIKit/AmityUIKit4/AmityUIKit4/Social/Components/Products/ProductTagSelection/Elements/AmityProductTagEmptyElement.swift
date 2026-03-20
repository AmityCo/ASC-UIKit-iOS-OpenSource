//
//  AmityProductTagEmptyElement.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/14/26.
//

import SwiftUI

struct AmityProductTagEmptyElement: AmityElementView {

    var pageId: PageId?
    var componentId: ComponentId?

    var id: ElementId {
        return .productTagEmpty
    }

    @EnvironmentObject var viewConfig: AmityViewConfigController

    var body: some View {
        AmityView(configId: configId,
                  config: { configDict -> String in
            let text = configDict["text"] as? String ?? "Start typing to search for products"
            return text
        }) { text in
            VStack(spacing: 16) {
                Image(AmityIcon.defaultSearchIcon.getImageResource())
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 36)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade4))

                Text(text)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColorShade3)))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 32)
        }
    }
}
