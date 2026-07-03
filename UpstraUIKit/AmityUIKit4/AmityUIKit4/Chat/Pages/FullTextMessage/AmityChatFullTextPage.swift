//
//  AmityChatFullTextPage.swift
//  AmityUIKit4
//

import SwiftUI

struct AmityChatFullTextPage: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper

    let fullText: String
    let displayName: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    host.controller?.navigationController?.popViewController(animated: true)
                } label: {
                    Image(AmityIcon.Chat.backButtonIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .padding(8)
                }
                .padding(.leading, 4)

                Spacer()

                Text(displayName)
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))

                Spacer()

                Color.clear
                    .frame(width: 40, height: 40)
            }
            .frame(height: 44)
            .background(Color(viewConfig.theme.backgroundColor))

            Divider()

            ScrollView {
                Text(fullText)
                    .applyTextStyle(.title(Color(viewConfig.theme.baseColor)))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .background(Color(viewConfig.theme.backgroundColor))
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
}
