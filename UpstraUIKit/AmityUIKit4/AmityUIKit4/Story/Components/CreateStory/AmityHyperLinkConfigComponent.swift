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
    
    public init(isPresented: Binding<Bool>, data: Binding<HyperLinkModel>) {
        self._isPresented = isPresented
        self._data = data
    }
    
    public var body: some View {
        NavigationView {
            VStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor(hex: "#EBECEF")))
                
                InfoTextField(data: $urlTextFieldModel,
                              text: $viewModel.urlText,
                              isValid: $viewModel.isURLValid,
                              titleTextAccessibilityId: AccessibilityID.Story.AmityHyperLinkConfigComponent.hyperlinkURLTitleTextView,
                              textFieldAccessibilityId: AccessibilityID.Story.AmityHyperLinkConfigComponent.hyperlinkURLTextField,
                              descriptionTextAccessibilityId: AccessibilityID.Story.AmityHyperLinkConfigComponent.hyperlinkErrorTextView)
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
            .navigationTitle("Add link")
            .accessibilityIdentifier(AccessibilityID.Story.AmityHyperLinkConfigComponent.titleTextView)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isUnsavedAlertShown.toggle()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.black)
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
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        Task { @MainActor in
                            guard await checkValidation(urlStr: viewModel.urlText, word: viewModel.urlNameText) else { return }
                            
                            data.url = viewModel.urlText
                            data.urlName = viewModel.urlNameText
                            isPresented.toggle()
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.isURLValid || viewModel.urlText.isEmpty)
                    .accessibilityIdentifier(AccessibilityID.Story.AmityHyperLinkConfigComponent.doneButton)
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
                        .foregroundColor(.red)
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
                .foregroundColor(Color(UIColor(hex: "#EBECEF")))
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
        AmityHyperLinkConfigComponent(isPresented: $isPresented, data: $data)
    }
    
}

#if DEBUG
#Preview {
    Preview()
}
#endif