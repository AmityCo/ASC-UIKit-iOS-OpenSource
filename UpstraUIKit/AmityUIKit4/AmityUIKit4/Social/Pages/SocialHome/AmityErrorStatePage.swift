//
//  AmityErrorStatePage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/15/25.
//

import SwiftUI

struct AmityErrorStatePage: View {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController = AmityViewConfigController(pageId: .socialHomePage)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 14) {
                Image(AmityIcon.emptyStateExplore.imageResource)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                
                VStack(spacing: 10) {
                    Text("Something went wrong")
                        .applyTextStyle(.headline(Color(viewConfig.theme.baseColorShade2)))
                        .multilineTextAlignment(.center)

                    Text("The content you're looking for is unavailable.")
                        .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade3)))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }

            Spacer()

            VStack(spacing: 16) {
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)

                Button {
                    host.controller?.dismissOrPop()
                } label: {
                    Text("OK")
                        .applyTextStyle(.bodyBold(.white))
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(height: 40)
                .background(Color(viewConfig.theme.primaryColor))
                .cornerRadius(8, corners: .allCorners)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
}
