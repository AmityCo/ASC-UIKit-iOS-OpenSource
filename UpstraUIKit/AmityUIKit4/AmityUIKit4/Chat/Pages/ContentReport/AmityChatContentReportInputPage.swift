//
//  AmityChatContentReportInputPage.swift
//  AmityUIKit4
//
//  Chat-prefixed, design-system clone of AmityContentReportInputPage.
//  Figma: [UIKit 4.0] Chat (xt0KYneEXrCO37HBIFgYT9), node 10848:55001.
//

import SwiftUI

struct AmityChatContentReportInputPage: View {

    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @EnvironmentObject var viewConfig: AmityViewConfigController

    @ObservedObject var viewModel: AmityChatContentReportPageViewModel

    /// See AmityChatContentReportPage.onSuccess — routes the success toast to the caller.
    private let onSuccess: ((String) -> Void)?

    @State private var text: String = ""
    @State private var textEditorHeight: CGFloat = 0

    private let maxCharCount = 300
    private let minEditorHeight: CGFloat = 40
    private let maxEditorLineLimit = 6

    init(viewModel: AmityChatContentReportPageViewModel, onSuccess: ((String) -> Void)? = nil) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.onSuccess = onSuccess
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            dragHandle

            ZStack {
                VStack(alignment: .leading, spacing: 0) {

                    navBar

                    inputField
                        .padding(.top, 24)
                        .padding([.horizontal, .bottom], 16)

                    Spacer()

                    AmityDivider(variant: .post, viewConfig: viewConfig)

                    submitButton
                }
                .onTapGesture {
                    hideKeyboard()
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

    private var navBar: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(AmityLocalizedStringSet.Social.reportReasonOthersPageTitle.localizedString)
                    .applyTextStyle(.titleBold(Color(viewConfig.color(.textSheetsHeaderTitleDefault))))
                    .frame(maxWidth: .infinity)

                HStack {
                    Button {
                        self.host.controller?.navigationController?.popViewController(animated: true)
                    } label: {
                        Image(AmityIcon.DesignSystem.chevronLeft.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(viewConfig.color(.iconIconButtonGhostSecondaryDefault)))
                            .frame(width: 24, height: 24)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        self.host.controller?.dismiss(animated: true)
                    } label: {
                        Image(AmityIcon.DesignSystem.crossR.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(viewConfig.color(.iconIconButtonGhostSecondaryDefault)))
                            .frame(width: 24, height: 24)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 44)

            AmityDivider(variant: .post, viewConfig: viewConfig)
        }
    }

    private var inputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Text(AmityLocalizedStringSet.Social.reportReasonOthersInputTitle.localizedString)
                        .applyTextStyle(.titleBold(Color(viewConfig.color(.textInputTextInputTitleDefault))))
                    Text(AmityLocalizedStringSet.General.optionalLabel.localizedString)
                        .applyTextStyle(.caption(Color(viewConfig.color(.textInputTextInputIndicatorDefault))))
                }
                Spacer()
                Text("\(text.count)/\(maxCharCount)")
                    .applyTextStyle(.caption(Color(viewConfig.color(.textInputTextInputTextCountDefault))))
            }

            ZStack(alignment: .topLeading) {
                // Invisible mirror text — measures the content height so the editor
                // grows with the text instead of taking the full available height.
                Text(text.isEmpty ? " " : text)
                    .applyTextStyle(.body(Color.clear))
                    .lineLimit(maxEditorLineLimit)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: ViewHeightKey.self, value: geo.size.height)
                    })

                if text.isEmpty {
                    Text(AmityLocalizedStringSet.Social.reportReasonOthersInputPlaceholder.localizedString)
                        .applyTextStyle(.body(Color(viewConfig.color(.textInputTextInputPlaceholderEnabled))))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .applyTextStyle(.body(Color(viewConfig.color(.textInputTextInputPlaceholderEnabledFilled))))
                    .transparentBackground()
                    .background(Color.clear)
                    .frame(height: max(minEditorHeight, textEditorHeight))
                    .onChange(of: text) { newValue in
                        if newValue.count > maxCharCount {
                            text = String(newValue.prefix(maxCharCount))
                        }
                    }
            }
            .onPreferenceChange(ViewHeightKey.self) { textEditorHeight = $0 }
            .padding(.bottom, 4)
            .overlay(
                Rectangle()
                    .fill(Color(viewConfig.color(.lineInputTextInputUnderlinedDefault)))
                    .frame(height: 1),
                alignment: .bottom
            )
        }
    }

    private var submitButton: some View {
        Button {
            Task { @MainActor in
                try await viewModel.flagContent(reason: .others(text))

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
            let isDisabled = viewModel.submissionState == .submitting
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
        .disabled(viewModel.submissionState == .submitting)
        .padding(16)
    }
}
