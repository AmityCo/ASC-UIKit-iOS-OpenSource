//
//  ChatMessageBubbleView.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK
import Combine

struct ChatMessageBubbleView<Content: View>: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let message: MessageModel
    let messageAction: AmityMessageAction
    let content: () -> Content
    let config: Configuration = .init()

    @StateObject var viewModel: ChatMessageBubbleViewModel
    @Namespace var overlayAnimationNamespace
    @State private var isPressed = false
    @State private var showingRepliedImageViewer = false
    @State private var showingRepliedVideoPlayer = false

    init(message: MessageModel, messageAction: AmityMessageAction, @ViewBuilder content: @escaping () -> Content) {
        self.message = message
        self.content = content
        self.messageAction = messageAction
        self._viewModel = StateObject(wrappedValue: ChatMessageBubbleViewModel(message: message))
    }

    private var messageFrameForOverlay: CGRect {
        guard message.hasReaction else { return viewModel.currentFrame }
        var rect = viewModel.currentFrame
        rect.size.height += 24
        return rect
    }

    var body: some View {
        if message.isOwner {
            senderRow
        } else {
            receiverRow
        }
    }

    // MARK: - Sender row (right-aligned, no avatar)

    private var senderRow: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Spacer(minLength: 60)

            if !message.isDeleted {
                VStack(alignment: .trailing, spacing: 4) {
                    if message.parentId != nil {
                        replySection(isOwner: true)
                    }

                    HStack(alignment: message.syncState == .error ? .center : .bottom, spacing: 0) {
                        MessageStatusView(
                            message: message,
                            dateFormat: config.timestampConfig.dateFormatter,
                            viewModel: viewModel,
                            messageAction: messageAction,
                            showReportedIndicator: false
                        )

                        ZStack(alignment: .bottomTrailing) {
                            content()
                                .matchedGeometryEffect(id: message.id, in: overlayAnimationNamespace)
                                .modifier(ChatSenderMessageBubble(
                                    isBubbleEnabled: config.isBubbleEnabled(messageType: message.type),
                                    message: message,
                                    isPressed: isPressed,
                                    onSeeMore: { messageAction.onSeeMore?(message.text) },
                                    viewModel: viewModel
                                ))
                                .onLongPressGesture(minimumDuration: 0.3) {
                                    guard message.syncState == .synced else { return }
                                    ImpactFeedbackGenerator.impactFeedback(style: .medium)
                                    isPressed = true
                                    ReactionOverlayController.showChatOverlay(
                                        message: message,
                                        messageAction: messageAction,
                                        nameSpace: overlayAnimationNamespace,
                                        messageFrame: messageFrameForOverlay,
                                        content: content,
                                        onDismiss: { isPressed = false }
                                    )
                                }

                            AmityChatMessageReactionPreview(message: message, tapAction: {
                                messageAction.showReaction?(message)
                            })
                            .offset(x: 0, y: 20)
                            .opacity(message.hasReaction ? 1 : 0)
                            .allowsHitTesting(message.hasReaction)
                        }
                        .captureViewFrameInWindow { rect in
                            viewModel.currentFrame = rect
                        }
                    }
                    // The (i) can be covered on cancelled media, so catch its tap on the
                    // container, gated to the icon's frame. (Drag = iOS-14 tap location.)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .global).onEnded { value in
                            guard message.syncState == .error else { return }
                            // a tap, not a scroll
                            guard abs(value.translation.width) < 10,
                                  abs(value.translation.height) < 10 else { return }
                            // only when the touch is on the (i)
                            guard viewModel.errorIconFrame.contains(value.location) else { return }
                            messageAction.onFailedTap?(message)
                        }
                    )
                }
                .padding(.trailing, 16)
                .padding(.top, 4)
                .padding(.bottom, (message.hasReaction) ? 16 : 0)
            } else {
                deletedMessageView(isOwner: true)
                    .padding(.trailing, 16)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Receiver row (left-aligned, with avatar + display name)

    private var receiverRow: some View {
        HStack(alignment: .bottom, spacing: 8) {
            MessageAvatarView(message: message, placeholderIcon: config.placeholderConfig.receiverAvatar)
                .padding(.leading, 16)
                .accessibilityIdentifier(AccessibilityID.Chat.MessageList.bubbleReceiverAvatar)

            VStack(alignment: .leading, spacing: 4) {
                if message.isGroupChat && message.parentId == nil {
                    Text(message.displayName)
                        .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade1)))
                        .accessibilityIdentifier(AccessibilityID.Chat.MessageList.bubbleReceiverDisplayName)
                }

                if message.parentId != nil && !message.isDeleted {
                    replySection(isOwner: false)
                }

                HStack(alignment: .bottom, spacing: 0) {
                    if !message.isDeleted {
                        ZStack(alignment: .bottomLeading) {
                            content()
                                .matchedGeometryEffect(id: message.id, in: overlayAnimationNamespace)
                                .modifier(ChatReceiverMessageBubble(
                                    isBubbleEnabled: config.isBubbleEnabled(messageType: message.type),
                                    message: message,
                                    isPressed: isPressed,
                                    onSeeMore: { messageAction.onSeeMore?(message.text) },
                                    viewModel: viewModel
                                ))
                                .onLongPressGesture(minimumDuration: 0.3) {
                                    guard message.syncState == .synced else { return }
                                    ImpactFeedbackGenerator.impactFeedback(style: .medium)
                                    isPressed = true
                                    ReactionOverlayController.showChatOverlay(
                                        message: message,
                                        messageAction: messageAction,
                                        nameSpace: overlayAnimationNamespace,
                                        messageFrame: messageFrameForOverlay,
                                        content: content,
                                        onDismiss: { isPressed = false }
                                    )
                                }

                            AmityChatMessageReactionPreview(message: message, tapAction: {
                                messageAction.showReaction?(message)
                            })
                            .offset(x: 0, y: 20)
                            .opacity(message.hasReaction ? 1 : 0)
                            .allowsHitTesting(message.hasReaction)
                        }
                        .captureViewFrameInWindow { rect in
                            viewModel.currentFrame = rect
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 0)
                        .padding(.trailing, 6)

                        MessageStatusView(
                            message: message,
                            dateFormat: config.timestampConfig.dateFormatter,
                            viewModel: viewModel,
                            messageAction: messageAction,
                            showReportedIndicator: false
                        )
                    } else {
                        deletedMessageView(isOwner: false)
                    }

                    Spacer()
                }
            }
        }
        .padding(.top, 4)
        .padding(.bottom, (message.hasReaction && !message.isDeleted) ? 16 : 0)
    }

    // MARK: - Reply section (header + quoted bubble), rendered above main bubble row

    @ViewBuilder
    private func replySection(isOwner: Bool) -> some View {
        VStack(alignment: isOwner ? .trailing : .leading, spacing: 4) {
            if let replied = viewModel.repliedMessage {
                HStack(spacing: 4) {
                    Image(AmityIcon.Chat.replyButtonIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 16, height: 12)
                        .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                    Text(replyLabel(isOwner: isOwner))
                        .applyTextStyle(.custom(12, .regular, Color(viewConfig.theme.baseColorShade1)))
                        .lineLimit(1)
                }

                repliedBubbleView(replied: replied, isOwner: isOwner)
                    .contentShape(Rectangle())
                    .onTapGesture { onRepliedBubbleTapped() }
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(width: 228, height: 60)
                    .shimmering()
            }
        }
        .padding(.bottom, 4)
        .fullScreenCover(isPresented: $showingRepliedImageViewer) {
            if let parent = viewModel.repliedParent {
                MediaViewer(
                    url: parent.imageURL ?? parent.mediumFileURL,
                    viewConfig: viewConfig,
                    closeAction: { showingRepliedImageViewer = false },
                    saveImageURL: parent.largeImageURL,
                    onDelete: nil
                )
            }
        }
        .fullScreenCover(isPresented: $showingRepliedVideoPlayer) {
            if let url = viewModel.repliedParent?.videoPlaybackURL {
                VideoMessagePlayerView(videoURL: url)
                    .ignoresSafeArea()
            }
        }
    }

    private func onRepliedBubbleTapped() {
        guard let parent = viewModel.repliedParent, !parent.isDeleted else { return }
        switch parent.type {
        case .image:
            showingRepliedImageViewer = true
        case .video:
            guard parent.videoPlaybackURL != nil else { return }
            showingRepliedVideoPlayer = true
        default:
            guard !parent.text.isEmpty else { return }
            (messageAction.onSeeMoreReplied ?? messageAction.onSeeMore)?(parent.text)
        }
    }

    // MARK: Reply header label

    private func replyLabel(isOwner: Bool) -> String {
        guard let replied = viewModel.repliedMessage else {
            return AmityLocalizedStringSet.Chat.Bubble.replyYou.localizedString
        }

        if replied.isDeleted {
            return isOwner
                ? AmityLocalizedStringSet.Chat.Bubble.replyYouToDeleted.localizedString
                : AmityLocalizedStringSet.Chat.Bubble.replyToDeleted.localizedString
        }

        let currentUserId = AmityUIKit4Manager.client.currentUserId ?? ""
        let isParentCurrentUser = !replied.userId.isEmpty
            && replied.userId == currentUserId

        func truncate(_ name: String) -> String {
            let safe = name.isEmpty
                ? AmityLocalizedStringSet.Chat.Bubble.unknownUser.localizedString
                : name
            return safe.count <= 10 ? safe : String(safe.prefix(10)) + "..."
        }

        if !message.isGroupChat {
            if isParentCurrentUser {
                return isOwner
                    ? AmityLocalizedStringSet.Chat.Bubble.replyYouToYourself.localizedString
                    : AmityLocalizedStringSet.Chat.Bubble.replyToYou.localizedString
            } else {
                return isOwner
                    ? AmityLocalizedStringSet.Chat.Bubble.replyYou.localizedString
                    : AmityLocalizedStringSet.Chat.Bubble.replyToThemself.localizedString
            }
        }

        let parentName = truncate(replied.displayName)
        let senderName = truncate(message.displayName)

        if isParentCurrentUser {
            if isOwner {
                return AmityLocalizedStringSet.Chat.Bubble.replyYouToYourself.localizedString
            } else {
                return String.localizedStringWithFormat(
                    AmityLocalizedStringSet.Chat.Bubble.replyNameToYou.localizedString,
                    senderName
                )
            }
        } else {
            if isOwner {
                return String.localizedStringWithFormat(
                    AmityLocalizedStringSet.Chat.Bubble.replyYouToName.localizedString,
                    parentName
                )
            } else if !replied.userId.isEmpty && replied.userId == message.userId {
                return String.localizedStringWithFormat(
                    AmityLocalizedStringSet.Chat.Bubble.replyNameToThemself.localizedString,
                    senderName
                )
            } else {
                return String.localizedStringWithFormat(
                    AmityLocalizedStringSet.Chat.Bubble.replyNameToName.localizedString,
                    senderName, parentName
                )
            }
        }
    }

    @ViewBuilder
    private func repliedBubbleView(replied: MessageModel.RepliedMessage, isOwner: Bool) -> some View {
        if replied.isDeleted {
            HStack(spacing: 4) {
                Image(AmityIcon.Chat.deletedMessageIcon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 14)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                Text(AmityLocalizedStringSet.Chat.deletedMessage.localizedString)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1))
        } else if replied.type == .image, let url = replied.imageURL {
            ZStack {
                AsyncImage(placeholderView: { Color(viewConfig.theme.baseColorShade4) }, url: url)
                    .scaledToFill().frame(width: 120, height: 120).clipped()
                Color.white.opacity(0.6)
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        } else if replied.type == .image {
            ZStack {
                RoundedRectangle(cornerRadius: 20).fill(Color(viewConfig.theme.baseColorShade4))
                Color.white.opacity(0.6)
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        } else if replied.type == .video, let url = replied.videoThumbnailURL {
            ZStack {
                AsyncImage(placeholderView: { Color(viewConfig.theme.baseColorShade4) }, url: url)
                    .scaledToFill().frame(width: 120, height: 120).clipped()
                Image(AmityIcon.Chat.videoPlayButtonIcon.imageResource).resizable().frame(width: 40, height: 40)
                Color.white.opacity(0.6)
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        } else if replied.type == .video {
            ZStack {
                RoundedRectangle(cornerRadius: 20).fill(Color(viewConfig.theme.baseColorShade4))
                Image(AmityIcon.Chat.videoPlayButtonIcon.imageResource).resizable().frame(width: 40, height: 40)
                Color.white.opacity(0.6)
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        } else {
            replyPreviewText(for: replied.text)
                .lineLimit(2)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20).fill(Color(viewConfig.theme.baseColorShade4))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.6))
                        .allowsHitTesting(false)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .frame(maxWidth: 228, alignment: isOwner ? .trailing : .leading)
        }
    }

    @ViewBuilder
    private func replyPreviewText(for text: String) -> some View {
        let safe = text.isEmpty ? " " : text
        if #available(iOS 15, *) {
            Text(makeReplyAttributedText(safe))
        } else {
            Text(safe)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
        }
    }

    @available(iOS 15, *)
    private func makeReplyAttributedText(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.font = .system(size: 15, weight: .regular)
        attributed.foregroundColor = Color(viewConfig.theme.baseColor)

        let links = AmityPreviewLinkWizard.shared.extractLinks(from: text)
        for link in links {
            guard let stringRange = Range(link.range, in: text),
                  let lowerBound = AttributedString.Index(stringRange.lowerBound, within: attributed),
                  let upperBound = AttributedString.Index(stringRange.upperBound, within: attributed) else {
                continue
            }
            let attrRange = lowerBound..<upperBound
            attributed[attrRange].foregroundColor = Color(viewConfig.theme.highlightColor)
            attributed[attrRange].underlineStyle = .single
        }
        return attributed
    }

    // MARK: - Deleted message view

    func deletedMessageView(isOwner: Bool) -> some View {
        let iconTextColor = isOwner
            ? Color(viewConfig.theme.highlightColor)
            : Color(viewConfig.theme.baseColorShade2)
        let content = HStack(spacing: 4) {
            Image(AmityIcon.Chat.deletedMessageIcon.imageResource)
                .renderingMode(.template)
                .frame(width: 16, height: 14)
                .foregroundColor(iconTextColor)

            Text(AmityLocalizedStringSet.Chat.deletedMessage.localizedString)
                .foregroundColor(iconTextColor)
        }
        if isOwner {
            return AnyView(content.modifier(ChatSenderMessageBubble(
                isBubbleEnabled: true,
                message: message,
                viewModel: viewModel
            )))
        } else {
            return AnyView(content.modifier(ChatReceiverMessageBubble(
                isBubbleEnabled: true,
                message: message,
                viewModel: viewModel
            )))
        }
    }

    // MARK: - Configuration

    struct Configuration: UIKitConfigurable {
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
            return messageType != .image && messageType != .video && messageType != .file
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
