//
//  AmityChatContentReportPage.swift
//  AmityUIKit4
//
//  Chat-prefixed, design-system clone of AmityContentReportPage.
//  Figma: [UIKit 4.0] Chat (xt0KYneEXrCO37HBIFgYT9), node 10848:54988.
//

import SwiftUI
import AmitySDK

// Internal Page
struct AmityChatContentReportPage: View {

    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @EnvironmentObject var viewConfig: AmityViewConfigController

    @StateObject private var viewModel: AmityChatContentReportPageViewModel
    @State private var reasons: [AmityContentFlagReason] = [
        .communityGuidelines,
        .harassmentOrBullying,
        .selfHarmOrSuicide,
        .violenceOrThreateningContent,
        .sellingRestrictedItems,
        .sexualContentOrNudity,
        .spamOrScams,
        .falseInformation
    ]

    /// Called with the success message after the report sheet dismisses, so the
    /// caller can present the toast in its own context (e.g. above the chat's
    /// compose bar divider). Falls back to the global toast when nil.
    private let onSuccess: ((String) -> Void)?

    init(type: ChatContentReportType, onSuccess: ((String) -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: AmityChatContentReportPageViewModel(type: type))
        self.onSuccess = onSuccess
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            dragHandle

            ZStack {
                VStack(alignment: .leading, spacing: 0) {

                    Text(AmityLocalizedStringSet.Social.reportReasonPageTitle.localizedString)
                        .applyTextStyle(.titleBold(Color(viewConfig.color(.textSheetsHeaderTitleDefault))))
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 12)

                    AmityDivider(variant: .post, viewConfig: viewConfig)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {

                            Text(AmityLocalizedStringSet.Social.reportPageInfoLabel.localizedString)
                                .applyTextStyle(.caption(Color(viewConfig.color(.textListTextDescriptionDefaultDefault))))
                                .padding(.vertical, 12)

                            ForEach(reasons, id: \.description) { item in
                                reasonRow(item)
                            }

                            othersRow
                        }
                    }
                    .padding(.horizontal, 16)

                    AmityDivider(variant: .post, viewConfig: viewConfig)

                    submitButton
                }

                ChatContentReportErrorView(action: {
                    self.host.controller?.dismiss(animated: true)
                })
                .visibleWhen(viewModel.submissionState == .contentError)
            }
        }
        .background(Color(viewConfig.color(.surfaceSheetsBackgroundGeneral)).ignoresSafeArea())
    }

    // MARK: - Subviews

    private var dragHandle: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(viewConfig.color(.surfaceSheetsHandleDefault)))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)
            Spacer()
        }
    }

    private func reasonRow(_ item: AmityContentFlagReason) -> some View {
        Button {
            viewModel.selectedReason = item
        } label: {
            HStack(spacing: 12) {
                Text(item.localizedDescription)
                    .applyTextStyle(.bodyBold(Color(viewConfig.color(.textListHeaderDefaultDefault))))

                Spacer()

                AmitySelection(variant: .radio,
                               isSelected: viewModel.selectedReason?.isEqual(item: item) ?? false,
                               viewConfig: viewConfig) { _, _ in }
                    .allowsHitTesting(false)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var othersRow: some View {
        Button {
            let inputPage = AmityChatContentReportInputPage(viewModel: viewModel, onSuccess: onSuccess)
                .updateTheme(with: viewConfig)
            let vc = AmitySwiftUIHostingController(rootView: inputPage)
            self.host.controller?.navigationController?.pushViewController(vc, animated: true)
        } label: {
            HStack {
                Text(AmityContentFlagReason.others("").localizedDescription)
                    .applyTextStyle(.bodyBold(Color(viewConfig.color(.textListHeaderDefaultDefault))))

                Spacer()

                Image(AmityIcon.DesignSystem.chevronRight.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(viewConfig.color(.iconListLeadingDefaultDefault)))
                    .frame(width: 24, height: 24)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var submitButton: some View {
        Button {
            guard let reason = viewModel.selectedReason else { return }

            Task { @MainActor in
                try await viewModel.flagContent(reason: reason)

                if viewModel.submissionState == .success {
                    let toastMessage = AmityLocalizedStringSet.Social.reportReasonSuccessToastMessage.localized(arguments: viewModel.type.description)
                    self.host.controller?.dismiss(animated: true) {
                        if let onSuccess {
                            onSuccess(toastMessage)
                        } else {
                            Toast.showToast(style: .success, message: toastMessage)
                        }
                    }
                }
            }
        } label: {
            let isDisabled = viewModel.selectedReason == nil || viewModel.submissionState == .submitting
            Text(AmityLocalizedStringSet.Social.reportPageSubmitButton.localizedString)
                .applyTextStyle(.bodyBold(Color(viewConfig.color(
                    isDisabled
                        ? .textMainButtonDefaultFilledPrimaryDisabled
                        : .textMainButtonDefaultFilledPrimaryEnabled))))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(viewConfig.color(
                    isDisabled
                        ? .surfaceMainButtonDefaultFilledPrimaryDisabled
                        : .surfaceMainButtonDefaultFilledPrimaryEnabled)))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.selectedReason == nil || viewModel.submissionState == .submitting)
        .padding(16)
    }
}
