//
//  LiveChatMessageBubbleView.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 22/3/2567 BE.
//

import SwiftUI
import AmitySDK
import Combine

struct LiveChatMessageBubbleView<Content: View>: View {
    
    let message: MessageModel
    let messageAction: AmityMessageAction
    let content: () -> Content
    let config: Configuration = .init()
    
    @StateObject var viewModel: LiveChatMessageBubbleViewModel
    
    init(message: MessageModel, messageAction: AmityMessageAction, @ViewBuilder content: @escaping () -> Content) {
        self.message = message
        self.content = content
        self.messageAction = messageAction
        self._viewModel = StateObject(wrappedValue: LiveChatMessageBubbleViewModel(message: message))
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Avatar
            MessageAvatarView(message: message, placeholderIcon: message.isOwner ? config.placeholderConfig.senderAvatar : config.placeholderConfig.receiverAvatar)
                .padding(.leading, 16)
                .accessibilityIdentifier(message.isOwner ? AccessibilityID.Chat.MessageList.bubbleSenderAvatar : AccessibilityID.Chat.MessageList.bubbleReceiverAvatar)
            
            VStack(alignment: .leading, spacing: 4) {
                // User Info
                Text(message.displayName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#A5A9B5"))
                    .accessibilityIdentifier(message.isOwner ? AccessibilityID.Chat.MessageList.bubbleSenderDisplayName : AccessibilityID.Chat.MessageList.bubbleReceiverDisplayName)
                
                HStack(alignment: .bottom, spacing: 0) {
                    if !message.isDeleted {
                        ZStack(alignment: .bottomLeading) {
                            content()
                                .modifier(LiveChatMessageBubble(isBubbleEnabled: config.isBubbleEnabled(messageType: message.type), message: message, viewModel: viewModel))
                                .contextMenu(menuItems: {
                                    
                                    Button {
                                        let replyModel = message
                                        messageAction.onReply?(replyModel)
                                    } label: {
                                        Label(AmityLocalizedStringSet.Chat.replyButton.localizedString, systemImage: "arrowshape.turn.up.left")
                                    }
                                    .isHidden(message.syncState == .error)
                                    
                                    Button {
                                        messageAction.onCopy?(message)
                                    } label: {
                                        Label(AmityLocalizedStringSet.Chat.copyButton.localizedString, systemImage: "doc.on.doc")
                                    }
                                    
                                    if message.isOwner || message.hasModeratorPermissionInChannel {
                                        
                                        if #available(iOS 15.0, *) {
                                            
                                            Button(role: .destructive) {
                                                messageAction.onDelete?(message)
                                            } label: {
                                                Label(AmityLocalizedStringSet.Chat.deleteButton.localizedString, systemImage: "trash")
                                            }
                                        } else {
                                            
                                            Button {
                                                messageAction.onDelete?(message)
                                            } label: {
                                                Label(AmityLocalizedStringSet.Chat.deleteButton.localizedString, systemImage: "trash")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }
                                })
                            
                            /// For Reaction
                            //                            MessageReactionBubble(message: message)
                            //                                .offset(x: 0, y: 18)
                            //                                .isHidden(message.hasReaction ? false : true)
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 0)
                        .padding(.trailing, 6)
                        
                        MessageStatusView(message: message, dateFormat: config.timestampConfig.dateFormatter)
                        
                    } else {
                        HStack(spacing: 4) {
                            Image(AmityIcon.trashBinWhiteIcon.getImageResource())
                                .frame(width: 12, height: 16)
                            Text(AmityLocalizedStringSet.Chat.deletedMessage.localizedString)
                        }
                        .modifier(LiveChatMessageBubble(isBubbleEnabled: config.isBubbleEnabled(messageType: message.type), message: message, viewModel: viewModel))
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.top, 4)
        
    }
    
    struct Configuration: UIKitConfigurable {
        // Load message_bubble config + sender bubble config
        
        var timestampConfig: TimestampConfiguration = .init(config: [:])
        var placeholderConfig: PlaceholderConfiguration = .init(config: [:])
        
        var pageId: PageId?
        var componentId: ComponentId?
        var elementId: ElementId?
        
        
        init() {
            self.pageId = nil
            self.componentId = .messageList
            
            let mainConfig = AmityUIKitConfigController.shared.getConfig(configId: configId)
            timestampConfig = TimestampConfiguration(config: mainConfig)
            placeholderConfig = PlaceholderConfiguration(config: mainConfig)
            
        }
        
        func isBubbleEnabled(messageType: AmityMessageType) -> Bool {
            return messageType != .image
        }
        
        struct TimestampConfiguration {
            var dateFormatter: DateFormatter
            
            init(config: [String: Any]) {
                let dateFormat = config["timestamp_format"] as? String ?? "h:mm a"
                
                let dateFormatter = DateFormatter()
                dateFormatter.calendar = Date.calendar
                
                dateFormatter.dateStyle = .none
                dateFormatter.timeStyle = .short
                dateFormatter.dateFormat = dateFormat
                
                self.dateFormatter = dateFormatter
            }
        }
        
        struct PlaceholderConfiguration {
            
            var senderAvatar: ImageResource
            var receiverAvatar: ImageResource
            
            init(config: [String: Any]) {
                self.senderAvatar = AmityIcon.getImageResource(named: config["sender_placeholder"] as? String ?? "chatAvatarPlaceholder")
                self.receiverAvatar = AmityIcon.getImageResource(named: config["receiver_placeholder"] as? String ?? "chatAvatarPlaceholder")
            }
            
        }
    }
}

struct RepliedMessage {
    let displayName: String
    let text: String
}

class LiveChatMessageBubbleViewModel: ObservableObject {
    let message: MessageModel
    let messageRepo = AmityMessageRepository(client: AmityUIKit4Manager.client)
    let reactionRepo = AmityReactionRepository(client: AmityUIKit4Manager.client)
    
    @Published var repliedMessage: RepliedMessage?
    var token: AmityNotificationToken?
    
    init(message: MessageModel) {
        self.message = message
        if let parentId = message.parentId {
            if let cacheMessage = MessageReplyCache.shared.cachedParentMessage[parentId] {
                repliedMessage = RepliedMessage(displayName: cacheMessage.displayName , text: cacheMessage.text)
            } else {
                token = messageRepo.getMessage(parentId).observeOnce({ [weak self] message, error in
                    
                    let snapshot = message.snapshot
                    
                    self?.repliedMessage = RepliedMessage(displayName: snapshot?.user?.displayName ?? "", text: snapshot?.data?["text"] as? String ?? "")
                })
            }
        }
    }
    
    func addRaction() async {
        do {
            let _ = try await reactionRepo.addReaction("heart", referenceId: message.id, referenceType: .message)
        } catch {
            Log.chat.debug("Error while adding reaction \(error)")
        }
    }
    
}
