//
//  AmityAltTextConfigComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 4/20/25.
//

import SwiftUI
import AmitySDK

public enum AltTextMedia {
    case image(AmityImageData)
    case video(AmityImageData)
}

public enum AltTextConfigMode {
    case create(AltTextMedia)
    case edit(String, AltTextMedia)
}

public struct AmityAltTextConfigComponent: AmityComponentIdentifiable, View {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @Environment(\.presentationMode) private var presentationMode
    
    public var pageId: PageId?
    public var id: ComponentId {
        .altTextConfig
    }
    
    @State private var altText: String = ""
    @State private var characterCount: Int = 0
    @StateObject private var viewConfig: AmityViewConfigController
    private var isEditMode: Bool = false
    private var currentAltText: String = ""
    private var image: AmityImageData?
    private let maxCharacterCount = 180
    private let result: (String) -> Void
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var isConnected: Bool = false
    @State private var isKeyboardOnScreen = false
    private let fileRepositoryManager = FileRepositoryManager()
    
    public init(mode: AltTextConfigMode, result: @escaping (String) -> Void,  pageId: PageId? = nil) {
        self.pageId = pageId
        self.result = result
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .altTextConfig))
        
        if case let .edit(text, media) = mode {
            self.isEditMode = true
            self.currentAltText = text
            if case let .image(image) = media {
                self.image = image
            }
            
            self._altText = State(initialValue: text)
            self._characterCount = State(initialValue: text.count)
        } else if case let .create(media) = mode {
            self.isEditMode = false
            self.currentAltText = ""
            if case let .image(image) = media {
                self.image = image
            }
        }
    }

    public var body: some View {
        VStack {
            BottomSheetDragIndicator()
                .foregroundColor(Color(viewConfig.defaultLightTheme.baseColorShade3))
            
            NavigationView {
                VStack(spacing: 0) {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                        .padding(.top, 4)
                    
                    // Image display
                    AsyncImage(placeholderView: {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }, url: URL(string: image?.mediumFileURL ?? "") ?? URL(string: ""))
                    .frame(width: 80, height: 80)
                    .clipped()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    
                    // Alt text field
                    TextEditor(text: $altText)
                        .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                        .padding(.horizontal, 8)
                        .overlay(
                            Group {
                                if altText.isEmpty {
                                    Text(AmityLocalizedStringSet.Social.altTextPlaceholder.localizedString)
                                        .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade3)))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                        .focused()
                    .onChange(of: altText) { newValue in
                        characterCount = newValue.count
                        if characterCount > maxCharacterCount {
                            ImpactFeedbackGenerator.impactFeedback(style: .medium)
                            altText = String(altText.prefix(maxCharacterCount))
                            characterCount = maxCharacterCount
                        }
                    }
                    
                    Spacer()
                }
                .navigationBarTitle("", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack {
                            let title = isEditMode ? AmityLocalizedStringSet.Social.altTextEditTitle.localizedString : AmityLocalizedStringSet.Social.altTextTitle.localizedString
                            Text(title)
                                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                            Text("\(characterCount)/\(maxCharacterCount)")
                                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Image(AmityIcon.closeIcon.getImageResource())
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                            .frame(width: 24, height: 24)
                            .onTapGesture {
                                presentationMode.wrappedValue.dismiss()
                            }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        let btnTitle = isEditMode ? AmityLocalizedStringSet.General.save.localizedString : AmityLocalizedStringSet.General.done.localizedString
                        Button(btnTitle) {
                            Task { @MainActor in
                                do {
                                    try await checkValidation(altText: altText)
                                    try await fileRepositoryManager.fileRepository.updateAltText(fileId: image?.fileId ?? "", altText: altText)
                                    result(altText)
                                    presentationMode.wrappedValue.dismiss()
                                } catch {
                                    var errorMessage = isEditMode ? AmityLocalizedStringSet.Social.altTextFailedToEdit.localizedString : AmityLocalizedStringSet.Social.altTextFailedToAdd.localizedString
                                    if error.isAmityErrorCode(.banWordFound) {
                                        errorMessage = AmityLocalizedStringSet.Social.altTextIncludesBannedWords.localizedString
                                    } else if error.isAmityErrorCode(.linkNotAllowed) {
                                        errorMessage = AmityLocalizedStringSet.Social.altTextIncludesNotAllowedLink.localizedString
                                    }
                                    
                                    Toast.showToast(style: .warning, message: errorMessage, bottomPadding: isKeyboardOnScreen ? 150 : 0)
                                }
                            }
                        }
                        .disabled(shouldDisableDoneButton())
                        .foregroundColor(shouldDisableDoneButton() ? Color(viewConfig.theme.primaryColor.blend(.shade2)) : Color(viewConfig.theme.primaryColor))
                    }
                }
            }
        }
        .onChange(of: networkMonitor.isConnected) { isConnected in
            Log.add(event: .info, "NetworkConnect: \(isConnected ? "Connected" : "Disconnected")")
            self.isConnected = isConnected
            if !isConnected {
                Toast.showToast(style: .warning, message: AmityLocalizedStringSet.General.noInternetConnection.localizedString, bottomPadding: isKeyboardOnScreen ? 150 : 0)
            }
        }
        .onReceive(keyboardPublisher) { keyboardEvent in
            isKeyboardOnScreen = keyboardEvent.isAppeared
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
    }
    
    private func shouldDisableDoneButton() -> Bool {
        if isEditMode {
            return altText == currentAltText || !isConnected
        } else {
            return altText.isEmpty || !isConnected
        }
    }
    
    private func checkValidation(altText: String) async throws {
        guard isConnected else {
            Toast.showToast(style: .warning, message: AmityLocalizedStringSet.General.noInternetConnection.localizedString)
            return
        }
        
        let urls = detectLinks(in: altText)
    
        if !altText.isEmpty {
            do {
                let _ = try await AmityUIKitManagerInternal.shared.client.validateTexts(texts: [altText])
                if !urls.isEmpty {
                    let _  = try await AmityUIKitManagerInternal.shared.client.validateUrls(urls: urls)
                }
            } catch {
                throw error
            }
        }
    }
    
    private func detectLinks(in text: String) -> [String] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        
        let stringRange = NSRange(location: 0, length: text.count)
        let linkMatches = detector.matches(in: text, options: [], range: stringRange)
        
        // Get all links
        var links = [String]()
        for linkMatch in linkMatches {
            guard let swiftRange = Range(linkMatch.range, in: text) else { continue }
            links.append(String(text[swiftRange]))
        }
        
        return links
    }
}

