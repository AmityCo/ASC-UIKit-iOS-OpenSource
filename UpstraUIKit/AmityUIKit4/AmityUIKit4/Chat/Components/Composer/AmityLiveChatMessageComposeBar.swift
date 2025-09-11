//
//  AmityLiveChatMessageComposeBar.swift
//  AmityUIKit4
//
//  Created by Nishan on 16/2/2567 BE.
//

import SwiftUI
import AmitySDK

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
                                    try await viewModel.updateTextMessage(text: currentInput)
                                    
                                    mentionData = MentionData()
                                case .reply:
                                    try await viewModel.createReplyMessage(text: currentInput, mentionData: mentionData)
                                    
                                    mentionData = MentionData()
                                }
                            } catch {
                                let errorMessage: String
                                
                                if error.isAmityErrorCode(.banWordFound) {
                                    
                                    errorMessage = AmityLocalizedStringSet.Chat.toastBannedWord.localizedString
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
                Alert(title: Text(AmityLocalizedStringSet.Chat.charLimitAlertTitle.localizedString), message: Text(AmityLocalizedStringSet.Chat.charLimitAlertMessage.localizedString), dismissButton: .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString)))
            })
            .alert(isPresented: $textEditorViewModel.reachMentionLimit) {
                return Alert(title: Text(AmityLocalizedStringSet.Chat.reachMentionLimitTitle.localizedString), message: Text(AmityLocalizedStringSet.Chat.reachMentionLimitMessage.localizedString), dismissButton: .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString), action: {
                }))
            }
        }
        .updateTheme(with: viewConfig)
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
