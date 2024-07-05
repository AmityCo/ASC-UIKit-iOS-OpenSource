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
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    let message: MessageModel
    let messageAction: AmityMessageAction
    let content: () -> Content
    let config: Configuration = .init()
    
    @StateObject var viewModel: LiveChatMessageBubbleViewModel
    @Namespace var overlayAnimationNamespace
    
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
                    .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                    .accessibilityIdentifier(message.isOwner ? AccessibilityID.Chat.MessageList.bubbleSenderDisplayName : AccessibilityID.Chat.MessageList.bubbleReceiverDisplayName)
                
                HStack(alignment: .bottom, spacing: 0) {
                    if !message.isDeleted {
                        ZStack(alignment: .bottomLeading) {
                            content()
                                .matchedGeometryEffect(id: message.id, in: overlayAnimationNamespace)
                                .modifier(LiveChatMessageBubble(isBubbleEnabled: config.isBubbleEnabled(messageType: message.type), message: message, viewModel: viewModel))
                                .background(GeometryReader { geometry -> Color in
                                    let rect = geometry.frame(in: .global)
                                    DispatchQueue.main.async {
                                        viewModel.currentPosition = rect.origin
                                        viewModel.currentFrame = rect
                                    }
                                    return Color.clear
                                })
                                .onLongPressGesture(minimumDuration: 0.3) {
                                    ImpactFeedbackGenerator.impactFeedback(style: .medium)
                                    
                                    ReactionOverlayController.showOverlay(message: message, messageAction: messageAction, nameSpace: overlayAnimationNamespace, messageFrame: viewModel.currentFrame, content: content)
                                }
                            
                            AmityLiveChatMessageReactionPreview(message: message, tapAction: {
                                messageAction.showReaction?(message)
                            })
                            .offset(x: 0, y: 20)
                            .opacity(message.hasReaction ? 1 : 0)
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 0)
                        .padding(.trailing, 6)
                        
                        MessageStatusView(message: message, dateFormat: config.timestampConfig.dateFormatter, viewModel: viewModel, messageAction: messageAction)
                        
                    } else {
                        deletedMessageView
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.top, 4)
        .padding(.bottom, (message.hasReaction && !message.isDeleted) ? 16 : 0)
    }
    
    var deletedMessageView: some View {
        HStack(spacing: 4) {
            Image(AmityIcon.trashBinWhiteIcon.getImageResource())
                .renderingMode(.template)
                .frame(width: 12, height: 16)
                .foregroundColor(Color(viewConfig.theme.baseColor))
            
            Text(AmityLocalizedStringSet.Chat.deletedMessage.localizedString)
                .foregroundColor(Color(viewConfig.theme.baseColor))
        }
        .modifier(LiveChatMessageBubble(isBubbleEnabled: config.isBubbleEnabled(messageType: message.type), message: message, viewModel: viewModel))
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

class LiveChatMessageBubbleViewModel: ObservableObject {
    let message: MessageModel
    let messageRepo = AmityMessageRepository(client: AmityUIKit4Manager.client)
    let reactionRepo = AmityReactionRepository(client: AmityUIKit4Manager.client)
    
    @Published var repliedMessage: MessageModel.RepliedMessage?
    @Published var isReportedByMe: Bool = false
    var token: AmityNotificationToken?
    
    var currentPosition: CGPoint = CGPoint(x: 0, y: 0)
    var currentFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    
    init(message: MessageModel) {
        self.message = message
        
        updateParentMessageForReply(message: message)
        
        // Update flag status for new messages
        updateReportStatus(message: message)
    }
    
    func updateParentMessageForReply(message: MessageModel) {
        if let parentId = message.parentId {
            if let cacheMessage = MessageCache.shared.cachedParentMessage[parentId] {
                repliedMessage = MessageModel.RepliedMessage(displayName: cacheMessage.displayName , text: cacheMessage.text)
            } else {
                token = messageRepo.getMessage(parentId).observeOnce({ [weak self] message, error in
                    let snapshot = message.snapshot
                    self?.repliedMessage = MessageModel.RepliedMessage(displayName: snapshot?.user?.displayName ?? "", text: snapshot?.data?["text"] as? String ?? "")
                })
            }
        }
    }
    
    func updateReportStatus(message: MessageModel) {
        if message.flagCount > 0 {
            if let isFlaggedByMe = MessageCache.shared.isFlaggedByMe(messageId: message.id) {
                isReportedByMe = isFlaggedByMe
            } else {
                // If its not present in cache, we fetch status
                fetchOwnerReportStatus(message: message)
            }
        } else {
            // Reset cache
            MessageCache.shared.setFlagStatus(messageId: message.id, value: false)
        }
    }
    
    func fetchOwnerReportStatus(message: MessageModel) {
        let messageId = message.id
        Task { @MainActor [weak self] in
            guard let self else { return }
            
            let reportStatus = try await self.messageRepo.isMessageFlaggedByMe(withId: messageId)
            
            // Add to cache
            MessageCache.shared.setFlagStatus(messageId: messageId, value: reportStatus)
            
            // Update report status immediately.
            self.isReportedByMe = reportStatus
        }
    }
}

