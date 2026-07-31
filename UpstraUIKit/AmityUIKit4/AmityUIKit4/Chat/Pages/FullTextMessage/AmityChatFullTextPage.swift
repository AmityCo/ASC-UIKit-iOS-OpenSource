//
//  AmityChatFullTextPage.swift
//  AmityUIKit4
//

import SwiftUI
import SafariServices

struct AmityChatFullTextPage: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper

    let message: MessageModel
    let displayName: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    host.controller?.navigationController?.popViewController(animated: true)
                } label: {
                    Image(AmityIcon.DesignSystem.chevronLeft.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color(viewConfig.color(.iconIconButtonGhostSecondaryDefault)))
                        .padding(8)
                }
                .padding(.leading, 4)

                Spacer()

                Text(displayName)
                    .applyTextStyle(.titleBold(Color(viewConfig.color(.textSheetsHeaderTitleDefault))))

                Spacer()

                Color.clear
                    .frame(width: 40, height: 40)
            }
            .frame(height: 44)
            .background(Color(viewConfig.color(.surfaceSheetsBackgroundGeneral)))

            ScrollView {
                textContent
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .background(Color(viewConfig.color(.surfacePageBackgroundDefault)))
        }
        .background(Color(viewConfig.color(.surfacePageBackgroundDefault)).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }

    @ViewBuilder
    private var textContent: some View {
        if #available(iOS 15, *) {
            
            let mentionFont = AmityTextStyle.titleBold(.clear).getUIFont()
            let linkColor = viewConfig.color(.textChatBubbleInboundLinkDefault)
            let mentionAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: linkColor,
                .font: mentionFont
            ]
            let linkAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: linkColor,
                .underlineStyle: Text.LineStyle(pattern: .solid)
            ]
            let attributedText = TextHighlighter.getAttributedText(from: message, highlightAttributes: mentionAttrs, linkAttributes: linkAttrs)
            Text(attributedText)
                .applyTextStyle(.title(Color(viewConfig.color(.textChatBubbleInboundMessagesDefault))))
                .environment(\.openURL, OpenURLAction { url in
                    let base = url.deletingLastPathComponent().absoluteString
                    if base == TextHighlighter.mentionURL
                        || base == TextHighlighter.hashtagURL
                        || base == TextHighlighter.productTagURL {
                        return .discarded
                    }
                    
                    let browserVC = SFSafariViewController(url: url)
                    browserVC.modalPresentationStyle = .pageSheet
                    UIApplication.topViewController()?.present(browserVC, animated: true)
                    return .discarded
                })
        } else {
            Text(message.text)
                .applyTextStyle(.title(Color(viewConfig.color(.textChatBubbleInboundMessagesDefault))))
        }
    }
}
