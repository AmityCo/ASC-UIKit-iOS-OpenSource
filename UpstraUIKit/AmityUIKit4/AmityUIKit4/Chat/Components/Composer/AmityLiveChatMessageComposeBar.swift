//
//  AmityLiveChatMessageComposeBar.swift
//  AmityUIKit4
//
//  Created by Nishan on 16/2/2567 BE.
//

import SwiftUI
import AmitySDK
import PhotosUI

public struct AmityLiveChatMessageComposeBar: AmityComponentView {
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        return .messageComposer
    }
    
    private let config: Configuration
    
    @StateObject var viewModel: AmityMessageComposerViewModel
    @StateObject var textEditorViewModel: AmityTextEditorViewModel
    @State private var mentionData: MentionData = MentionData()
    @State private var showingLongMessageAlert = false
    @State private var showingMediaPicker = false
    @State private var showingCameraPicker = false
    @State private var showingCameraPermissionAlert = false
    @State private var isSendingMedia = false
    @State private var showMediaSection = false
    private var chatPageViewModel: AmityLiveChatPageViewModel
    
    @StateObject private var viewConfig: AmityViewConfigController
    
    public init(viewModel: AmityLiveChatPageViewModel, pageId: PageId? = .liveChatPage) {
        self.pageId = pageId
        self.chatPageViewModel = viewModel
        self.config = Configuration.init(pageId: pageId, componentId: .messageComposer)
        self._viewModel = StateObject(wrappedValue: viewModel.composer)
        self._textEditorViewModel = StateObject(wrappedValue: AmityTextEditorViewModel(mentionManager: MentionManager(withType: .message(subChannelId: viewModel.channelId))))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .messageComposer))
    }
    
    // Text that user types
    @State private var input: String = ""
    @State private var mentionedUsers: [AmityMentionUserModel] = []
    
    public var body: some View {
        VStack(spacing: 0) {
            
            AmityMentionUserListView(mentionedUsers: $mentionedUsers, selection: { selectedMention in
                // Ask view model to handle this selection
                textEditorViewModel.selectMentionUser(user: selectedMention)
                
                // Update attributed Input
                self.input = textEditorViewModel.textView.text
                
                mentionData.mentionee = textEditorViewModel.mentionManager.getMentionees()
                mentionData.metadata = textEditorViewModel.mentionManager.getMetadata()
                
            }, paginate: {
                textEditorViewModel.loadMoreMentions()
            })
            .background(Color(viewConfig.theme.baseColorShade4))
            .isHidden(mentionedUsers.count == 0)
            .accessibilityIdentifier(AccessibilityID.Chat.MentionList.container)
            
            if case let .edit(message) = viewModel.action {
                AmityTextMessageEditPreview(message: message) {
                    viewModel.action = .default
                    input = ""
                }
            }
            
            if case let .reply(message) = viewModel.action {
                AmityTextMessageReplyPreview(message: message) {
                    viewModel.action = .default
                    input = ""
                }
                .accessibilityIdentifier(AccessibilityID.Chat.ReplyPanel.container)
            }
            
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
            
            HStack(alignment: .bottom) {
                
                // MARK: "+" media toggle button
                if !isEditing {
                    Button {
                        if showMediaSection {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showMediaSection = false
                            }
                        } else {
                            textEditorViewModel.textView.resignFirstResponder()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showMediaSection = true
                            }
                        }
                    } label: {
                        Image(systemName: showMediaSection ? "xmark.circle.fill" : "plus.circle.fill")
                            .font(AmityTextStyle.custom(28, .regular, .clear).getFont())
                            .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                            .frame(width: 32, height: 32)
                            .padding(.bottom, 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(chatPageViewModel.messageList.muteState != .none && !chatPageViewModel.messageList.hasModeratorPermission)
                }

                // Default UITextView height should be Initial Text Height + Text Container Top Inset + Text Container Bottom Inset
                // In our case, it would be 18 + 8 + 8. This would prevent initial textview height changes
                AmityMessageTextEditorView(textEditorViewModel, text: $input, mentionData: $mentionData, mentionedUsers: $mentionedUsers, textViewHeight: 34)
                    .placeholder(config.text.placeholder)
                    .padding([.horizontal], 12)
                    .padding([.vertical], 6)
                    .background(RoundedRectangle(cornerRadius: 22) // Initial height is
                        .fill(Color(viewConfig.theme.baseColorShade4))
                    )
                    .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentComposer.textField)
                    .disabled(chatPageViewModel.messageList.muteState != .none && !chatPageViewModel.messageList.hasModeratorPermission)
                    .onChange(of: input) { _ in
                        if showMediaSection {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showMediaSection = false
                            }
                        }
                    }
                
                Button(action: {
                    let currentAction = viewModel.action
                    let currentInput = input
                    
                    if currentInput.count > config.messageLimit {
                        showingLongMessageAlert = true
                    } else {
                        
                        Task {
                            do {
                                switch currentAction {
                                case .default:
                                    try await viewModel.createTextMessage(text: currentInput, mentionData: mentionData) // Pass message limit from configuration here if needed.
                                    
                                    // reset
                                    mentionData = MentionData()
                                case .edit:
                                    try await viewModel.updateTextMessage(text: currentInput, mentionData: mentionData)
                                    
                                    mentionData = MentionData()
                                case .reply:
                                    try await viewModel.createReplyMessage(text: currentInput, mentionData: mentionData)
                                    
                                    mentionData = MentionData()
                                }
                            } catch {
                                let errorMessage: String
                                
                                if error.isAmityErrorCode(.banWordFound) {
                                    
                                    errorMessage = AmityLocalizedStringSet.Social.msgBlockedWord.localizedString
                                } else if error.isAmityErrorCode(.linkNotAllowed) {
                                    
                                    errorMessage = AmityLocalizedStringSet.Chat.toastLinkNotAllow.localizedString
                                } else {
                                    
                                    errorMessage = error.localizedDescription
                                }
                                chatPageViewModel.showToastMessage(message: errorMessage, style: .warning)
                            }
                        }
                        
                        input = ""
                        textEditorViewModel.reset()
                    }
                }, label: {
                    Image(config.image.sendButton)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .padding(.leading, 6)
                        .padding(.vertical, 8)
                })
                .accessibilityIdentifier(AccessibilityID.Chat.MessageComposer.sendButton)
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            }
            .padding(.vertical, 10)
            .padding(.horizontal)
            .background(Color(viewConfig.theme.backgroundColor))
            .alert(isPresented: $showingLongMessageAlert, content: {
                Alert(title: Text(AmityLocalizedStringSet.Chat.charLimitAlertTitle.localizedString), message: Text(AmityLocalizedStringSet.Social.yourMessageIsTooLongPleaseShortenYourMessageAn.localizedString), dismissButton: .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString)))
            })
            .alert(isPresented: $textEditorViewModel.reachMentionLimit) {
                return Alert(title: Text(AmityLocalizedStringSet.Chat.reachMentionLimitTitle.localizedString), message: Text(AmityLocalizedStringSet.Chat.reachMentionLimitMessage.localizedString), dismissButton: .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString), action: {
                }))
            }

            // MARK: Media section
            if showMediaSection {
                mediaSection
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .updateTheme(with: viewConfig)
        .onChange(of: isEditing) { editing in
            if editing && showMediaSection {
                showMediaSection = false
            }
        }
        .sheet(isPresented: $showingMediaPicker) {
            ChatMediaPickerView { selection in
                guard let selection else { return }
                isSendingMedia = true
                Task {
                    do {
                        switch selection.kind {
                        case .image:
                            try await viewModel.createImageMessage(imageURL: selection.url)
                        case .video:
                            try await viewModel.createVideoMessage(videoURL: selection.url)
                        }
                    } catch {
                        let toast: String = error.isInappropriateImageUpload
                            ? AmityLocalizedStringSet.Chat.EditGroupProfile.uploadFailedMessage.localizedString
                            : error.localizedDescription
                        chatPageViewModel.showToastMessage(message: toast, style: .warning)
                    }
                    isSendingMedia = false
                }
            }
        }
        .sheet(isPresented: $showingCameraPicker) {
            MessageCameraPickerView { selection in
                guard let selection else { return }
                isSendingMedia = true
                Task {
                    do {
                        switch selection.kind {
                        case .image:
                            try await viewModel.createImageMessage(imageURL: selection.url)
                        case .video:
                            try await viewModel.createVideoMessage(videoURL: selection.url)
                        }
                    } catch {
                        let toast: String = error.isInappropriateImageUpload
                            ? AmityLocalizedStringSet.Chat.EditGroupProfile.uploadFailedMessage.localizedString
                            : error.localizedDescription
                        chatPageViewModel.showToastMessage(message: toast, style: .warning)
                    }
                    isSendingMedia = false
                }
            }
        }
        .alert(isPresented: $showingCameraPermissionAlert) {
            Alert(
                title: Text(AmityLocalizedStringSet.Chat.ComposerCamera.deniedTitle.localizedString),
                message: Text(AmityLocalizedStringSet.Chat.ComposerCamera.deniedMessage.localizedString),
                primaryButton: .default(Text(AmityLocalizedStringSet.Chat.ComposerCamera.openSettings.localizedString), action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }),
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: - Helpers

    private var isEditing: Bool {
        if case .edit = viewModel.action { return true }
        return false
    }

    @ViewBuilder
    private var mediaSection: some View {
        HStack(spacing: 72) {
            mediaButton(
                systemImage: "camera.fill",
                label: AmityLocalizedStringSet.Chat.camera.localizedString
            ) {
                showMediaSection = false
                MessageCameraPermission.request { granted in
                    if granted {
                        showingCameraPicker = true
                    } else {
                        showingCameraPermissionAlert = true
                    }
                }
            }
            mediaButton(
                systemImage: "photo.fill.on.rectangle.fill",
                label: AmityLocalizedStringSet.Chat.mediaButton.localizedString
            ) {
                showMediaSection = false
                showingMediaPicker = true
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(viewConfig.theme.backgroundColor))
    }

    @ViewBuilder
    private func mediaButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(AmityTextStyle.custom(22, .regular, .clear).getFont())
                    .foregroundColor(Color(viewConfig.theme.primaryColor))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color(viewConfig.theme.baseColorShade4)))
                Text(label)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
            }
        }
        .buttonStyle(.plain)
        .disabled(chatPageViewModel.messageList.muteState != .none && !chatPageViewModel.messageList.hasModeratorPermission)
    }

    struct Configuration: UIKitConfigurable {
        
        var pageId: PageId?
        var componentId: ComponentId?
        var elementId: ElementId?
        
        var messageLimit = 200
        var text: TextConfig = .init(config: [:])
        var image: ImageConfig = .init(config: [:])
        
        init(pageId: PageId?, componentId: ComponentId?) {
            self.pageId = pageId
            self.componentId = componentId
            self.elementId = nil
            
            let mainConfig = AmityUIKitConfigController.shared.getConfig(configId: configId)
                        
            self.image = ImageConfig(config: getElementConfig(elementId: .sendButton))
            self.text = TextConfig(config: mainConfig)
            self.messageLimit = mainConfig["message_limit"] as? Int ?? 200
        }
        
        struct ImageConfig {
            let sendButton: ImageResource
            
            init(config: [String: Any]) {
                self.sendButton = AmityIcon.getImageResource(named: config["send_icon"] as? String ?? "sendIconEnable")
            }
        }
        
        struct TextConfig {
            let placeholder: String
            
            init(config: [String: Any]) {
                self.placeholder = config["placeholder_text"] as? String ?? ""
            }
        }
    }
}

// MARK: - PHPickerViewController wrapper (iOS 14+)

enum ChatMediaKind {
    case image
    case video
}

struct ChatMediaSelection {
    let url: URL
    let kind: ChatMediaKind
}

struct ChatMediaPickerView: UIViewControllerRepresentable {
    let onSelected: (ChatMediaSelection?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        if #available(iOS 15.0, *) {
            config.filter = PHPickerFilter.any(of: [.images, .videos])
        } else {
            config.filter = nil
        }
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onSelected: onSelected) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onSelected: (ChatMediaSelection?) -> Void
        var loadingOverlay: LoadingOverlayView?

        init(onSelected: @escaping (ChatMediaSelection?) -> Void) { self.onSelected = onSelected }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                picker.dismiss(animated: true)
                onSelected(nil)
                return
            }

            let videoType = "public.movie"
            let imageType = "public.image"

            let kind: ChatMediaKind
            let typeId: String
            let defaultExt: String
            if provider.hasItemConformingToTypeIdentifier(videoType) {
                kind = .video; typeId = videoType; defaultExt = "mov"
            } else if provider.hasItemConformingToTypeIdentifier(imageType) {
                kind = .image; typeId = imageType; defaultExt = "jpg"
            } else {
                picker.dismiss(animated: true)
                onSelected(nil)
                return
            }

            DispatchQueue.main.async {
                self.showLoadingOverlay(on: picker.view,
                                        message: AmityLocalizedStringSet.Social.mediaProcessing.localizedString)
            }

            provider.loadFileRepresentation(forTypeIdentifier: typeId) { url, _ in
                let ext = (url?.pathExtension.isEmpty == false ? url!.pathExtension : defaultExt)
                guard let url else {
                    DispatchQueue.main.async {
                        self.hideLoadingOverlay()
                        picker.dismiss(animated: true)
                        self.onSelected(nil)
                    }
                    return
                }
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(ext)
                try? FileManager.default.copyItem(at: url, to: tempURL)
                DispatchQueue.main.async {
                    self.hideLoadingOverlay()
                    picker.dismiss(animated: true)
                    self.onSelected(ChatMediaSelection(url: tempURL, kind: kind))
                }
            }
        }

        private func showLoadingOverlay(on view: UIView, message: String) {
            let overlay = LoadingOverlayView(message: message)
            loadingOverlay = overlay
            view.addSubview(overlay)
            overlay.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                overlay.topAnchor.constraint(equalTo: view.topAnchor),
                overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        private func hideLoadingOverlay() {
            loadingOverlay?.removeFromSuperview()
            loadingOverlay = nil
        }
    }
}

extension View {
    
    func transparentBackground() -> some View {
        if #available(iOS 16.0, *) {
            return scrollContentBackground(.hidden)
        } else {
            return onAppear {
                UITextView.appearance().backgroundColor = .clear
            }
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 0) {
        Color.white
        
        AmityLiveChatMessageComposeBar(viewModel: AmityLiveChatPageViewModel(channelId: "1234"))
    }
}
#endif

