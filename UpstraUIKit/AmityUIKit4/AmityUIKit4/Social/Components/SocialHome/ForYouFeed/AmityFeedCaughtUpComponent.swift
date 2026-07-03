//
//  AmityFeedCaughtUpComponent.swift
//  AmityUIKit4
//
//  Created by Claude on 4/6/26.
//

import SwiftUI

public struct AmityFeedCaughtUpComponent: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var pageId: PageId?

    public var id: ComponentId {
        .feedCaughtUpComponent
    }

    @StateObject private var viewConfig: AmityViewConfigController

    private let titleText: String?
    private let ctaText: String?
    private let onSwitchRequested: () -> Void

    public init(pageId: PageId? = nil, title: String? = nil, ctaLabel: String? = nil, onSwitchRequested: @escaping () -> Void) {
        self.pageId = pageId
        self.titleText = title
        self.ctaText = ctaLabel
        self.onSwitchRequested = onSwitchRequested
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .feedCaughtUpComponent))
    }

    public var body: some View {
        VStack(spacing: 0) {
            Image(AmityIcon.endOfFeedCheckIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(Color(AmityFixedColor.shared.feedCaughtUpIcon))

            Spacer().frame(height: 8)

            Text(titleText ?? AmityLocalizedStringSet.Social.feedCaughtUpTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade2)))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isStaticText)

            Spacer().frame(height: 16)

            Button(action: { onSwitchRequested() }) {
                Text(ctaText ?? AmityLocalizedStringSet.Social.feedCaughtUpCTA.localizedString)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.primaryColor)))
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isButton)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }
}
