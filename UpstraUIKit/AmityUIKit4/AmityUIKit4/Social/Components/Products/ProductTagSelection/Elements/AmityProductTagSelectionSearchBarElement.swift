//
//  AmityProductTagSelectionSearchBarElement.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/14/26.
//

import SwiftUI

struct AmityProductTagSelectionSearchBarElement: AmityElementView {

    var pageId: PageId?
    var componentId: ComponentId?

    var id: ElementId {
        return .productTagSelectionSearchBar
    }

    @EnvironmentObject var viewConfig: AmityViewConfigController
    @Binding var searchText: String

    var body: some View {
        AmityView(configId: configId,
                  config: { configDict -> String in
            let placeholder = configDict["placeholder"] as? String ?? "Search by product name"
            return placeholder
        }) { placeholder in
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                    .frame(width: 20, height: 20)

                if #available(iOS 15.0, *) {
                    TextField("", text: $searchText)
                        .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                        .placeholder(when: searchText.isEmpty, placeholder: {
                            Text(placeholder)
                                .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade2)))
                        })
                        .submitLabel(.search)
                        .focused()
                } else {
                    TextField("", text: $searchText)
                        .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                        .placeholder(when: searchText.isEmpty, placeholder: {
                            Text(placeholder)
                                .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade2)))
                        })
                        .focused()
                }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                            .frame(width: 17, height: 17)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(viewConfig.theme.baseColorShade4))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
