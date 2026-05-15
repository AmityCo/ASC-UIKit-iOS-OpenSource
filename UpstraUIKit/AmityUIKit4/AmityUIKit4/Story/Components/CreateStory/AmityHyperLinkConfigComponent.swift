//
//  AmityHyperLinkConfigComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/23/24.
//

import SwiftUI
import Combine

public struct HyperLinkModel {
    public var url: String
    public var urlName: String
    
    public func getDomainName() -> String? {
        return URLHelper.concatProtocolIfNeeded(urlStr: url)?.host
    }
    
    public func getCustomName() -> String {
        return urlName
    }
}

public struct AmityHyperLinkConfigComponent: AmityComponentView {
    public var pageId: PageId?
    
    public var id: ComponentId {
        .hyperLinkConfigComponent
    }
    
    @Binding private var isPresented: Bool
    @Binding private var data: HyperLinkModel
    @StateObject private var viewModel = AmityHyperLinkConfigComponentViewModel()
    @State private var isRemoveLinkAlertShown: Bool = false
    
    @State private var showActivityIndicator: Bool = false
    
    @State private var urlTextFieldModel = InfoTextFieldModel(title: AmityLocalizedStringSet.Social.hyperlinkUrlLabel.localizedString, placeholder: AmityLocalizedStringSet.Social.hyperlinkUrlHint.localizedString, isMandatory: true, errorMessage: AmityLocalizedStringSet.Social.enterValidUrl.localizedString)
    @State private var urlNameTextFieldModel = InfoTextFieldModel(title: AmityLocalizedStringSet.Social.customizeLinkText.localizedString, placeholder: AmityLocalizedStringSet.Social.hyperlinkNameHint.localizedString, isMandatory: false, infoMessage: AmityLocalizedStringSet.Social.hyperlinkCustomizeInfo.localizedString, errorMessage: AmityLocalizedStringSet.Social.textContainsBlocklisted.localizedString, maxCharCount: 30)
    
    @StateObject private var viewConfig: AmityViewConfigController
    @Environment(\.colorScheme) private var colorScheme
    
    public init(isPresented: Binding<Bool>, data: Binding<HyperLinkModel>, pageId: PageId?) {
        self._isPresented = isPresented
        self._data = data
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .hyperLinkConfigComponent))
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            navigationBar

            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))

            InfoTextField(data: $urlTextFieldModel,
                          text: $viewModel.urlText,
                          isValid: $viewModel.isURLValid,
                          titleTextAccessibilityId: AccessibilityID.Story.AmityHyperLinkConfigComponent.hyperlinkURLTitleTextView,
                          textFieldAccessibilityId: AccessibilityID.Story.AmityHyperLinkConfigComponent.hyperlinkURLTextField,
                          descriptionTextAccessibilityId: AccessibilityID.Story.AmityHyperLinkConfigComponent.hyperlinkErrorTextView)
            .alertColor(viewConfig.theme.alertColor)
            .dividerColor(viewConfig.theme.baseColorShade4)
            .infoTextColor(viewConfig.theme.baseColorShade2)
            .textFieldTextColor(viewConfig.theme.baseColor)
            .onChange(of: viewModel.urlText) { text in
                viewModel.isURLValid = text.isEmpty ? true : text.isValidURL

                if !text.isValidURL {
                    urlTextFieldModel.errorMessage = AmityLocalizedStringSet.Social.enterValidUrl.localizedString
                }
            }

            InfoTextField(data: $urlNameTextFieldModel,
                          text: $viewModel.urlNameText,
                          isValid: $viewModel.isURLNameValid,
                          titleTextAccessibilityId: AccessibilityID.Story.AmityHyperLinkConfigComponent.customizeLinkTitleTextView,
                          textFieldAccessibilityId: AccessibilityID.Story.AmityHyperLinkConfigComponent.customizeLinkTextField,
                          descriptionTextAccessibilityId: AccessibilityID.Story.AmityHyperLinkConfigComponent.customizeLinkDescriptionTextView,
                          charCountTextAccessibilityId: AccessibilityID.Story.AmityHyperLinkConfigComponent.customizeLinkCharacterLimitTextView)
            .alertColor(viewConfig.theme.alertColor)
            .dividerColor(viewConfig.theme.baseColorShade4)
            .infoTextColor(viewConfig.theme.baseColorShade2)
            .textFieldTextColor(viewConfig.theme.baseColor)
            .onChange(of: viewModel.urlNameText) { text in
                if text.isEmpty {
                    viewModel.isURLNameValid = true
                }
            }


            if !data.url.isEmpty {
                getRemoveLinkButton()
            }
            Spacer()
        }
        .padding([.leading, .trailing], 16)
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .accessibilityIdentifier(AccessibilityID.Story.AmityHyperLinkConfigComponent.componentContaier)
        .onChange(of: isPresented) { value in
            hideKeyboard()
            // Update the data as soon as this view is presented.
            if value {
                viewModel.urlText = data.url
                viewModel.urlNameText = data.urlName

                viewModel.isURLValid = true
                viewModel.isURLNameValid = true
            }
        }
        .overlay(
            ProgressView().progressViewStyle(.circular)
                .isHidden(!showActivityIndicator)
        )
        .onChange(of: colorScheme) { value in
            viewConfig.updateTheme()
        }
    }

    private var navigationBar: some View {
        HStack(alignment: .center, spacing: 0) {
            Button(action: {
                showUnsavedChangesAlert()
            }, label: {
                Text(viewConfig.getConfig(elementId: .cancelButtonElement, key: "cancel_button_text", of: String.self) ?? AmityLocalizedStringSet.General.cancel.localizedString)
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
            })
            .buttonStyle(.plain)
            .foregroundColor(Color(viewConfig.theme.baseColor))
            .accessibilityIdentifier(AccessibilityID.Story.AmityHyperLinkConfigComponent.cancelButton)
            .isHidden(viewConfig.isHidden(elementId: .cancelButtonElement))

            Spacer()

            Text(AmityLocalizedStringSet.Social.addLink.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                .accessibilityIdentifier(AccessibilityID.Story.AmityHyperLinkConfigComponent.titleTextView)

            Spacer()

            Button(action: {
                Task { @MainActor in
                    guard await checkValidation(urlStr: viewModel.urlText, word: viewModel.urlNameText) else { return }

                    data.url = viewModel.urlText
                    data.urlName = viewModel.urlNameText
                    isPresented.toggle()
                }
            }, label: {
                Text(viewConfig.getConfig(elementId: .doneButtonElement, key: "done_button_text", of: String.self) ?? AmityLocalizedStringSet.General.done.localizedString)
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
            })
            .buttonStyle(.plain)
            .foregroundColor(Color(viewConfig.theme.baseColor))
            .disabled(!viewModel.isURLValid || viewModel.urlText.isEmpty)
            .accessibilityIdentifier(AccessibilityID.Story.AmityHyperLinkConfigComponent.doneButton)
            .isHidden(viewConfig.isHidden(elementId: .doneButtonElement))
        }
        .frame(height: 38)
    }
    
    func getRemoveLinkButton() -> some View {
        VStack(alignment: .leading) {
            Button(action: {
                isRemoveLinkAlertShown.toggle()
            }, label: {
                HStack(spacing: 0) {
                    Image(AmityIcon.trashBinRedIcon.getImageResource())
                        .frame(width: 20, height: 20)
                        .padding(.trailing, 6)
                    Text(AmityLocalizedStringSet.Story.removeLinkButton.localizedString)
                        .applyTextStyle(.body(Color(viewConfig.theme.alertColor)))
                        .accessibilityIdentifier(AccessibilityID.Story.AmityHyperLinkConfigComponent.removeLinkButtonTextView)
                    Spacer()
                }
            })
            .alert(isPresented: $isRemoveLinkAlertShown) {
                Alert(title: Text(AmityLocalizedStringSet.Story.removeLinkTitle.localizedString),
                      message: Text(AmityLocalizedStringSet.Story.removeLinkMessage.localizedString),
                      primaryButton: .cancel(),
                      secondaryButton: .destructive(Text(AmityLocalizedStringSet.General.remove.localizedString), action: {
                    data.url = ""
                    data.urlName = ""
                    isPresented.toggle()
                }))
            }
            .accessibilityIdentifier(AccessibilityID.Story.AmityHyperLinkConfigComponent.removeLinkButton)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
        }
        .padding(EdgeInsets(top: 40, leading: 0, bottom: 0, trailing: 0))
        
        
    }
    
    private func showUnsavedChangesAlert() {
        let alert = UIAlertController(
            title: AmityLocalizedStringSet.Social.communitySetupEditAlertTitle.localizedString,
            message: AmityLocalizedStringSet.Story.unsavedChangesMessage.localizedString,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: AmityLocalizedStringSet.General.no.localizedString, style: .cancel))
        alert.addAction(UIAlertAction(title: AmityLocalizedStringSet.General.yes.localizedString, style: .default) { _ in
            isPresented = false
        })
        UIApplication.topViewController()?.present(alert, animated: true)
    }

    private func checkValidation(urlStr: String, word: String) async -> Bool {
        showActivityIndicator = true
        
        do {
            urlTextFieldModel.errorMessage = AmityLocalizedStringSet.Social.enterWhitelistedUrl.localizedString
            try await AmityUIKitManagerInternal.shared.client.validateUrls(urls: [urlStr])
            viewModel.isURLValid = true
        } catch {
            viewModel.isURLValid = false
        }
        
        if !word.isEmpty {
            do {
                try await AmityUIKitManagerInternal.shared.client.validateTexts(texts: [word])
                viewModel.isURLNameValid = true
            } catch {
                viewModel.isURLNameValid = false
            }
        }
        
        showActivityIndicator = false
        
        return viewModel.isURLValid && viewModel.isURLNameValid
    }
}

public class AmityHyperLinkConfigComponentViewModel: ObservableObject {
    @Published var urlText: String = ""
    @Published var isURLValid: Bool = true
    @Published var urlNameText: String = ""
    @Published var isURLNameValid: Bool = true
}


fileprivate struct Preview: View {
    @State var isPresented: Bool = false
    @State var data = HyperLinkModel(url: "www.youtube.com", urlName: "")
    
    var body: some View {
        AmityHyperLinkConfigComponent(isPresented: $isPresented, data: $data, pageId: nil)
    }
    
}

#if DEBUG
#Preview {
    Preview()
}
#endif
