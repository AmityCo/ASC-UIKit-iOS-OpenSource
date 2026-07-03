//
//  AmityChatMessageComposeBar.swift
//  AmityUIKit4
//
//  Compose bar used by DM (AmityChatPage) and group chat (AmityGroupChatPage).
//  Identical to AmityLiveChatMessageComposeBar except:
//    - Default pageId is nil (not .liveChatPage).
//    - Camera picker is presented with fullScreenCover so the native
//      UIImagePickerController camera UI shows both Photo and Video mode
//      toggles without being clipped by a sheet card.
//  AmityLiveChatMessageComposeBar is left untouched for the live-stream overlay.
//

import SwiftUI
import AmitySDK
import PhotosUI

public struct AmityChatMessageComposeBar: AmityComponentView {

    public var pageId: PageId?

    public var id: ComponentId {
        return .messageComposer
    }

    private let config: Configuration
    private let isGroupChat: Bool

    @StateObject var viewModel: AmityMessageComposerViewModel
    @StateObject var textEditorViewModel: AmityTextEditorViewModel
    @State private var mentionData: MentionData = MentionData()

    @State private var activeAlert: ComposeAlert?
    private enum ComposeAlert: Identifiable {
        case longMessage
        case mentionLimit
        case cameraDenied
        var id: Self { self }
    }
    @State private var showingMediaPicker = false
    @State private var showingCameraPicker = false
    @State private var isSendingMedia = false
    @State private var showMediaSection = false
    private var chatPageViewModel: AmityChatRoomViewModel

    @StateObject private var viewConfig: AmityViewConfigController

    public init(viewModel: AmityChatRoomViewModel, pageId: PageId? = nil, isGroupChat: Bool = false) {
        self.pageId = pageId
        self.isGroupChat = isGroupChat
        self.chatPageViewModel = viewModel
        self.config = Configuration.init(pageId: pageId, componentId: .messageComposer)
        self._viewModel = StateObject(wrappedValue: viewModel.composer)
        self._textEditorViewModel = StateObject(wrappedValue: AmityTextEditorViewModel(mentionManager: MentionManager(withType: .message(subChannelId: viewModel.channelId))))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .messageComposer))
    }

    @State private var input: String = ""
    @State private var mentionedUsers: [AmityMentionUserModel] = []
    @State private var draftBeforeEdit: String? = nil
    @State private var replyParentToken: AmityNotificationToken? = nil
    @State private var replyParentMessageId: String? = nil
    @State private var isReplyParentDeleted: Bool = false
    private let chatManager = ChatManager()

    private var isMuteBlocked: Bool {
        chatPageViewModel.messageList.muteState != .none && !chatPageViewModel.messageList.hasModeratorPermission
    }

    public var body: some View {
        VStack(spacing: 0) {

            if case let .edit(message) = viewModel.action {
                AmityTextMessageEditPreview(message: message) {
                    let restored = draftBeforeEdit ?? ""
                    viewModel.action = .default
                    input = restored
                    textEditorViewModel.textView.text = restored
                    draftBeforeEdit = nil
                }
            }

            if case let .reply(message) = viewModel.action {
                AmityTextMessageReplyPreview(message: message, isParentUnavailable: isReplyParentDeleted) {
                    viewModel.action = .default
                    isReplyParentDeleted = false
                    input = ""
                }
                .accessibilityIdentifier(AccessibilityID.Chat.ReplyPanel.container)
            }

            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)

            HStack(alignment: .bottom) {

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
                        Image(showMediaSection
                                ? AmityIcon.Chat.closeMediaSectionIcon.imageResource
                                : AmityIcon.Chat.openMediaSectionIcon.imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .padding(.bottom, 6)
                            .padding(.trailing, 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(chatPageViewModel.messageList.muteState != .none && !chatPageViewModel.messageList.hasModeratorPermission)
                }

                AmityMessageTextEditorView(textEditorViewModel, text: $input, mentionData: $mentionData, mentionedUsers: $mentionedUsers, textViewHeight: 34)
                    .displayInlineSuggestionView(isGroupChat)
                    .placeholder(config.text.placeholder)
                    .padding([.horizontal], 12)
                    .padding([.vertical], 6)
                    .background(RoundedRectangle(cornerRadius: 20)
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

                if !showMediaSection && !showingMediaPicker && !showingCameraPicker && !isSendingMedia {
                Button(action: {
                    guard !isMuteBlocked else { return }
                    let currentAction = viewModel.action
                    let currentInput = input

                    if currentInput.count > config.messageLimit {
                        activeAlert = .longMessage
                    } else {
                        Task {
                            do {
                                switch currentAction {
                                case .default:
                                    try await viewModel.createTextMessage(text: currentInput, mentionData: mentionData)
                                    mentionData = MentionData()
                                case .edit:
                                    try await viewModel.updateTextMessage(text: currentInput, mentionData: mentionData)
                                    mentionData = MentionData()
                                case .reply:
                                    try await viewModel.createReplyMessage(text: currentInput, mentionData: mentionData)
                                    mentionData = MentionData()
                                    await MainActor.run {
                                        textEditorViewModel.textView.resignFirstResponder()
                                    }
                                }
                            } catch {
                                let errorMessage: String
                                if error.isAmityErrorCode(.banWordFound) {
                                    errorMessage = AmityLocalizedStringSet.Chat.toastBannedWord.localizedString
                                } else if error.isAmityErrorCode(.linkNotAllowed) {
                                    errorMessage = AmityLocalizedStringSet.Chat.toastLinkNotAllow.localizedString
                                } else if case .reply = currentAction, error.isAmityErrorCode(.itemNotFound) {
                                    errorMessage = AmityLocalizedStringSet.Chat.toastReplyParentDeleted.localizedString
                                } else {
                                    errorMessage = error.localizedDescription
                                }
                                chatPageViewModel.showToastMessage(message: errorMessage, style: .warning)
                            }
                        }
                        input = ""
                        textEditorViewModel.reset()
                        draftBeforeEdit = nil
                    }
                }, label: {
                    let isInputEmpty = input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    let isBlocked = isInputEmpty || isReplyParentDeleted || isMuteBlocked
                    Image(isBlocked
                          ? AmityIcon.Chat.sendDisabledIcon.imageResource
                          : config.image.sendButton)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .padding(.leading, 12)
                        .padding(.bottom, 6)
                })
                .accessibilityIdentifier(AccessibilityID.Chat.MessageComposer.sendButton)
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isReplyParentDeleted || isMuteBlocked)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(viewConfig.theme.backgroundColor))
            .onChange(of: isGroupChat ? textEditorViewModel.reachMentionLimit : false) { isReached in
                if isReached {
                    activeAlert = .mentionLimit
                    textEditorViewModel.reachMentionLimit = false
                }
            }
            .onReceive(viewModel.$action) { newAction in
                switch newAction {
                case .edit:
                    SuggestionOverlayWindow.setTopReservedInset(48 + 1)
                case .reply:
                    SuggestionOverlayWindow.setTopReservedInset(62 + 1)
                case .default:
                    SuggestionOverlayWindow.setTopReservedInset(0)
                }

                if case let .edit(message) = newAction, draftBeforeEdit == nil {
                    draftBeforeEdit = input
                    input = message.text
                    textEditorViewModel.textView.text = message.text

                    if let metadata = message.metadata, !metadata.isEmpty {
                        textEditorViewModel.mentionManager.setMentions(metadata: metadata, inText: message.text)
                        mentionData.metadata = textEditorViewModel.mentionManager.getMetadata()
                        mentionData.mentionee = textEditorViewModel.mentionManager.getMentionees()
                    }
                }
                if case let .reply(message) = newAction {
                    DispatchQueue.main.async {
                        textEditorViewModel.textView.becomeFirstResponder()
                    }
                    if replyParentMessageId != message.id {
                        replyParentToken?.invalidate()
                        replyParentToken = nil
                        replyParentMessageId = message.id
                        isReplyParentDeleted = false
                        replyParentToken = chatManager.getMessage(messageId: message.id).observe { liveObject, _ in
                            guard let snapshot = liveObject.snapshot, snapshot.isDeleted else { return }
                            DispatchQueue.main.async {
                                isReplyParentDeleted = true
                            }
                        }
                    }
                } else {
                    replyParentToken?.invalidate()
                    replyParentToken = nil
                    replyParentMessageId = nil
                    isReplyParentDeleted = false
                }
            }

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
                        // No toast for user-cancelled uploads; keep it for genuine failures.
                        if !error.isUploadCancelled {
                            let toast: String = error.isInappropriateImageUpload
                                ? AmityLocalizedStringSet.Chat.EditGroupProfile.uploadFailedMessage.localizedString
                                : error.localizedDescription
                            chatPageViewModel.showToastMessage(message: toast, style: .warning)
                        }
                    }
                    isSendingMedia = false
                }
            }
        }
        .fullScreenCover(isPresented: $showingCameraPicker) {
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
                        // No toast for user-cancelled uploads; keep it for genuine failures.
                        if !error.isUploadCancelled {
                            let toast: String = error.isInappropriateImageUpload
                                ? AmityLocalizedStringSet.Chat.EditGroupProfile.uploadFailedMessage.localizedString
                                : error.localizedDescription
                            chatPageViewModel.showToastMessage(message: toast, style: .warning)
                        }
                    }
                    isSendingMedia = false
                }
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .longMessage:
                return Alert(
                    title: Text(AmityLocalizedStringSet.Chat.charLimitAlertTitle.localizedString),
                    message: Text(AmityLocalizedStringSet.Chat.charLimitAlertMessage.localizedString),
                    dismissButton: .default(Text(AmityLocalizedStringSet.Chat.doneButton.localizedString))
                )
            case .mentionLimit:
                return Alert(
                    title: Text(AmityLocalizedStringSet.Chat.reachMentionLimitTitle.localizedString),
                    message: Text(AmityLocalizedStringSet.Chat.reachMentionLimitMessage.localizedString),
                    dismissButton: .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString))
                )
            case .cameraDenied:
                return Alert(
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
                image: AmityIcon.Chat.cameraButtonIcon.imageResource,
                label: AmityLocalizedStringSet.Chat.camera.localizedString
            ) {
                showMediaSection = false
                MessageCameraPermission.request { granted in
                    if granted {
                        showingCameraPicker = true
                    } else {
                        activeAlert = .cameraDenied
                    }
                }
            }
            mediaButton(
                image: AmityIcon.Chat.imageButtonIcon.imageResource,
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
    private func mediaButton(image: ImageResource, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
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

        var messageLimit = 10000
        var text: TextConfig = .init(config: [:])
        var image: ImageConfig = .init(config: [:])

        init(pageId: PageId?, componentId: ComponentId?) {
            self.pageId = pageId
            self.componentId = componentId
            self.elementId = nil

            let mainConfig = AmityUIKitConfigController.shared.getConfig(configId: configId)
            self.image = ImageConfig(config: getElementConfig(elementId: .sendButton))
            self.text = TextConfig(config: mainConfig)
            self.messageLimit = mainConfig["message_limit"] as? Int ?? 10000
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
                self.placeholder = config["placeholder_text"] as? String ?? AmityLocalizedStringSet.Chat.messagePlaceholder.localizedString
            }
        }
    }
}
