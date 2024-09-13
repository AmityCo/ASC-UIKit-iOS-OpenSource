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
    @State private var isUnsavedAlertShown: Bool = false
    
    @State private var showActivityIndicator: Bool = false
    
    @State private var urlTextFieldModel = InfoTextFieldModel(title: "URL", placeholder: "https://example.com", isMandatory: true, errorMessage: "Please enter a valid URL.")
    @State private var urlNameTextFieldModel = InfoTextFieldModel(title: "Customize link text", placeholder: "Name your link", isMandatory: false, infoMessage: "This text will show on the link instead of URL.", errorMessage: "Your text contains a blocklisted word.", maxCharCount: 30)
    
    @StateObject private var viewConfig: AmityViewConfigController
    @Environment(\.colorScheme) private var colorScheme
    
    public init(isPresented: Binding<Bool>, data: Binding<HyperLinkModel>, pageId: PageId?) {
        self._isPresented = isPresented
        self._data = data
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .hyperLinkConfigComponent))
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 16) {
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
                        urlTextFieldModel.errorMessage = "Please enter a valid URL."
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
            .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
            .padding([.leading, .trailing], 16)
            .navigationTitle("Add link")
            .accessibilityIdentifier(AccessibilityID.Story.AmityHyperLinkConfigComponent.titleTextView)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        isUnsavedAlertShown.toggle()
                    }, label: {
                        Text(viewConfig.getConfig(elementId: .cancelButtonElement, key: "cancel_button_text", of: String.self) ?? "Cancel")
                            .font(.system(size: 15))
                    })
                    .buttonStyle(.plain)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .alert(isPresented: $isUnsavedAlertShown) {
                        Alert(title: Text("Unsaved changes"),
                              message: Text("Are you sure you want to cancel? Your changes won't be saved."),
                              primaryButton: .default(Text("No")
                                .foregroundColor(.accentColor)),
                              secondaryButton: .default(Text("Yes")
                                .foregroundColor(.accentColor), action: {
                            isPresented.toggle()
                        }))
                    }
                    .accessibilityIdentifier(AccessibilityID.Story.AmityHyperLinkConfigComponent.cancelButton)
                    .isHidden(viewConfig.isHidden(elementId: .cancelButtonElement))
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Task { @MainActor in
                            guard await checkValidation(urlStr: viewModel.urlText, word: viewModel.urlNameText) else { return }
                            
                            data.url = viewModel.urlText
                            data.urlName = viewModel.urlNameText
                            isPresented.toggle()
                        }
                    }, label: {
                        Text(viewConfig.getConfig(elementId: .doneButtonElement, key: "done_button_text", of: String.self) ?? "Done")
                            .font(.system(size: 15))
                    })
                    .buttonStyle(.plain)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .disabled(!viewModel.isURLValid || viewModel.urlText.isEmpty)
                    .accessibilityIdentifier(AccessibilityID.Story.AmityHyperLinkConfigComponent.doneButton)
                    .isHidden(viewConfig.isHidden(elementId: .doneButtonElement))
                }
            }
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
            .accessibilityIdentifier(AccessibilityID.Story.AmityHyperLinkConfigComponent.componentContaier)
        }
        .overlay(
            ProgressView().progressViewStyle(.circular)
                .isHidden(!showActivityIndicator)
        )
        .onChange(of: colorScheme) { value in
            viewConfig.updateTheme()
        }
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
                    Text("Remove link")
                        .font(.system(size: 15))
                        .foregroundColor(Color(viewConfig.theme.alertColor))
                        .accessibilityIdentifier(AccessibilityID.Story.AmityHyperLinkConfigComponent.removeLinkButtonTextView)
                    Spacer()
                }
            })
            .alert(isPresented: $isRemoveLinkAlertShown) {
                Alert(title: Text("Remove link?"),
                      message: Text("This link will be removed from story."),
                      primaryButton: .cancel(),
                      secondaryButton: .destructive(Text("Remove"), action: {
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
        .padding(EdgeInsets(top: 40, leading: 16, bottom: 0, trailing: 16))
        
        
    }
    
    private func checkValidation(urlStr: String, word: String) async -> Bool {
        showActivityIndicator = true
        
        do {
            urlTextFieldModel.errorMessage = "Please enter a whitelisted URL."
            let isWhitelistedURL = try await AmityUIKitManagerInternal.shared.client.validateUrls(urls: [urlStr])
            viewModel.isURLValid = isWhitelistedURL
        } catch {
            viewModel.isURLValid = false
        }
        
        if !word.isEmpty {
            do {
                let isValidWord = try await AmityUIKitManagerInternal.shared.client.validateTexts(texts: [word])
                viewModel.isURLNameValid = isValidWord
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
