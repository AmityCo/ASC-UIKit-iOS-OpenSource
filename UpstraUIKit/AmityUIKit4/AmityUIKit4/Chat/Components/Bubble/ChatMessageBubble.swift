//
//  ChatMessageBubble.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK

// MARK: - Receiver bubble (left side, baseColorShade4 background)

struct ChatReceiverMessageBubble: ViewModifier {

    let isBubbleEnabled: Bool
    let message: MessageModel
    var isPressed: Bool = false
    var onSeeMore: (() -> Void)? = nil

    @ObservedObject var viewModel: ChatMessageBubbleViewModel
    @EnvironmentObject var viewConfig: AmityViewConfigController

    func body(content: Content) -> some View {
        if isBubbleEnabled {
            if message.isDeleted {
                deletedBubble(content: content, isOwner: false)
            } else {
                plainBubble(content: content, isOwner: false)
            }
        } else {
            content
        }
    }
}

// MARK: - Sender bubble (right side, highlightColor background)

struct ChatSenderMessageBubble: ViewModifier {

    let isBubbleEnabled: Bool
    let message: MessageModel
    var isPressed: Bool = false
    var onSeeMore: (() -> Void)? = nil

    @ObservedObject var viewModel: ChatMessageBubbleViewModel
    @EnvironmentObject var viewConfig: AmityViewConfigController

    func body(content: Content) -> some View {
        if isBubbleEnabled {
            if message.isDeleted {
                deletedBubble(content: content, isOwner: true)
            } else {
                plainBubble(content: content, isOwner: true)
            }
        } else {
            content
        }
    }
}

// MARK: Shared helpers via protocol

private protocol ChatBubbleHelpers {
    var message: MessageModel { get }
    var viewModel: ChatMessageBubbleViewModel { get }
    var viewConfig: AmityViewConfigController { get }
    var isPressed: Bool { get }
    var onSeeMore: (() -> Void)? { get }
}

extension ChatReceiverMessageBubble: ChatBubbleHelpers {}
extension ChatSenderMessageBubble: ChatBubbleHelpers {}

extension ChatBubbleHelpers {

    // MARK: Plain bubble (no reply)
    @ViewBuilder
    func plainBubble(content: some View, isOwner: Bool) -> some View {
        let isEditedTextMessage = message.isEdited && !message.isDeleted && message.type == .text
        let bubbleColor: Color = isOwner
            ? (isPressed ? Color(UIColor(hex: "#1A4499")) : Color(viewConfig.theme.highlightColor))
            : (isPressed ? Color(UIColor(hex: "#A5A9B5")) : Color(viewConfig.theme.baseColorShade4))
        let subtleColor: Color = isOwner
            ? Color(viewConfig.theme.primaryColor.blend(.shade2))
            : Color(viewConfig.theme.baseColorShade1)

        PlainBubbleContainer(
            isEditedTextMessage: isEditedTextMessage,
            isOwner: isOwner,
            bubbleColor: bubbleColor,
            subtleColor: subtleColor,
            textColor: isOwner ? .white : Color(viewConfig.theme.baseColor),
            editedText: AmityLocalizedStringSet.Chat.Bubble.edited.localizedString,
            seeMoreText: AmityLocalizedStringSet.Chat.seeMore.localizedString,
            onSeeMore: onSeeMore,
            isPressed: isPressed,
            content: { content.font(AmityTextStyle.body(.clear).getFont()) }
        )
    }

    // MARK: Deleted bubble
    func deletedBubble(content: some View, isOwner: Bool) -> some View {
        let borderColor = isOwner
            ? Color(viewConfig.theme.highlightColor)
            : Color(viewConfig.theme.baseColorShade4)
        return content
            .font(AmityTextStyle.caption(.clear).getFont())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}

// MARK: - PlainBubbleContainer (owns @State for overflow detection)

private struct PlainBubbleContainer<C: View>: View {

    let isEditedTextMessage: Bool
    let isOwner: Bool
    let bubbleColor: Color
    let subtleColor: Color
    let textColor: Color
    let editedText: String
    let seeMoreText: String
    let onSeeMore: (() -> Void)?
    let isPressed: Bool
    let content: () -> C

    @State private var isOverflowing: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // --- Text content + edited label (padded) ---
            VStack(alignment: isOwner ? .trailing : .leading, spacing: 0) {
                content()

                if isEditedTextMessage {
                    Text(editedText)
                        .applyTextStyle(.custom(12, .regular, subtleColor))
                        .padding(.top, 12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // --- "See more" strip (full-width divider + button) ---
            if isOverflowing {
                Color(UIColor(red: 0.757, green: 0.757, blue: 0.757, alpha: 0.4))
                    .frame(height: 1)

                Button(action: { onSeeMore?() }) {
                    HStack {
                        Text(seeMoreText)
                            .applyTextStyle(.caption(subtleColor))
                        Spacer()
                        Image(AmityIcon.Chat.seeMoreArrowIcon.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 12)
                            .foregroundColor(subtleColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .onPreferenceChange(TextSizePairKey.self) { pair in
            isOverflowing = pair.isOverflowing
        }
        .background(bubbleColor)
        .foregroundColor(textColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .animation(.easeInOut(duration: 0.15), value: isPressed)
    }
}
