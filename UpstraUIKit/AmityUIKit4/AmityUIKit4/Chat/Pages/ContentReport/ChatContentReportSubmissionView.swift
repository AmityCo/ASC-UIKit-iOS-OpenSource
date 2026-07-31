//
//  ChatContentReportSubmissionView.swift
//  AmityUIKit4
//
//  Chat-prefixed clone of ContentReportSubmissionView, rebuilt on the design system.
//

import SwiftUI

struct ChatContentReportSuccessView: View {

    @StateObject private var viewConfig: AmityViewConfigController = AmityViewConfigController(pageId: nil)
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper

    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {

                Image(AmityIcon.reportSuccessIcon.imageResource)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .foregroundColor(Color(viewConfig.color(.surfaceMainButtonDefaultFilledPrimaryEnabled)))

                Text(AmityLocalizedStringSet.Social.reportThanksTitle.localizedString)
                    .applyTextStyle(.headline(Color(viewConfig.color(.textSheetsHeaderTitleDefault))))
                    .padding(.top, 16)

                Text(AmityLocalizedStringSet.Social.reportThanksMessage.localizedString)
                    .applyTextStyle(.body(Color(viewConfig.color(.textListTextDescriptionDefaultDefault))))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(32)
            .frame(maxWidth: .infinity)

            Spacer()

            AmityDivider(variant: .post, viewConfig: viewConfig)

            Button {
                action?()
            } label: {
                Text(AmityLocalizedStringSet.Social.reportReasonDoneButton.localizedString)
                    .applyTextStyle(.bodyBold(Color(viewConfig.color(.textMainButtonDefaultFilledPrimaryEnabled))))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(viewConfig.color(.surfaceMainButtonDefaultFilledPrimaryEnabled)))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(16)
        }
        .background(Color(viewConfig.color(.surfaceSheetsBackgroundGeneral)))
    }
}

struct ChatContentReportErrorView: View {

    @StateObject private var viewConfig: AmityViewConfigController = AmityViewConfigController(pageId: nil)
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper

    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {

                Image(AmityIcon.emptyStateExplore.imageResource)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 60, height: 40)
                    .foregroundColor(Color(viewConfig.color(.iconEmptyStateIconDefault)))

                Text(AmityLocalizedStringSet.Social.postDetailDeletedPostTitle.localizedString)
                    .applyTextStyle(.headline(Color(viewConfig.color(.textSheetsHeaderTitleDefault))))
                    .padding(.top, 16)

                Text(AmityLocalizedStringSet.Social.postDetailDeletedPostMessage.localizedString)
                    .applyTextStyle(.body(Color(viewConfig.color(.textListTextDescriptionDefaultDefault))))
                    .padding(.top, 8)
            }
            .padding(32)
            .frame(maxWidth: .infinity)

            Spacer()

            AmityDivider(variant: .post, viewConfig: viewConfig)

            Button {
                action?()
            } label: {
                Text(AmityLocalizedStringSet.Social.reportReasonCloseButton.localizedString)
                    .applyTextStyle(.bodyBold(Color(viewConfig.color(.textMainButtonDefaultFilledPrimaryEnabled))))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(viewConfig.color(.surfaceMainButtonDefaultFilledPrimaryEnabled)))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(16)
        }
        .background(Color(viewConfig.color(.surfaceSheetsBackgroundGeneral)))
    }
}
