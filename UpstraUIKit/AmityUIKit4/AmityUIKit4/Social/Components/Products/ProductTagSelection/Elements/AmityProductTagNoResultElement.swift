//
//  AmityProductTagNoResultElement.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/14/26.
//

import SwiftUI

struct AmityProductTagNoResultElement: AmityElementView {

    var pageId: PageId?
    var componentId: ComponentId?

    var id: ElementId {
        return .productTagNoResult
    }

    @EnvironmentObject var viewConfig: AmityViewConfigController

    var body: some View {
        AmityView(configId: configId,
                  config: { configDict -> String in
            let text = configDict["text"] as? String ?? "No results found"
            return text
        }) { text in
            VStack(spacing: 16) {
                Image(AmityIcon.noSearchableIcon.getImageResource())
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
