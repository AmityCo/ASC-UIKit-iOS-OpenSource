//
//  MessageStatusView.swift
//  AmityUIKit4
//
//  Created by Nishan on 19/2/2567 BE.
//

import SwiftUI

protocol MessageBubbleReportable: ObservableObject {
    var isReportedByMe: Bool { get }
    /// Global frame of the (i) icon, so the bubble container can hit-test taps on it.
    var errorIconFrame: CGRect { get set }
}

extension ChatMessageBubbleViewModel: MessageBubbleReportable {}
extension LiveChatMessageBubbleViewModel: MessageBubbleReportable {}

// Status (Flag / Unflag / Sent / Timestamp blabla)
struct MessageStatusView<VM: MessageBubbleReportable>: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let message: MessageModel
    let dateFormat: DateFormatter
    @ObservedObject var viewModel: VM
    let messageAction: AmityMessageAction
    let showReportedIndicator: Bool

    @State private var showSheet = false

    init(message: MessageModel, dateFormat: DateFormatter, viewModel: VM, messageAction: AmityMessageAction, showReportedIndicator: Bool = true) {
        self.message = message
        self.dateFormat = dateFormat
        self.viewModel = viewModel
        self.messageAction = messageAction
        self.showReportedIndicator = showReportedIndicator
    }
    
    @ViewBuilder
    private var errorStatusGlyph: some View {
        if message.isUploadCancelled {
            Image(AmityIcon.Chat.greyRetryIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color(viewConfig.theme.baseColorShade4)))
        } else {
            Image(AmityIcon.Chat.messageErrorIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(Color(viewConfig.theme.baseColorShade2))
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            if message.syncState == .error {
                errorStatusGlyph
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    // Simultaneous so an overlapping view can't swallow the tap.
                    .simultaneousGesture(TapGesture().onEnded {
                        if messageAction.onFailedTap != nil {
                            messageAction.onFailedTap?(message)
                        } else {
                            showSheet.toggle()
                        }
                    })
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear { viewModel.errorIconFrame = proxy.frame(in: .global) }
                                .onChange(of: proxy.frame(in: .global)) { viewModel.errorIconFrame = $0 }
                        }
                    )
                    .padding(.trailing, 4)
                    .zIndex(1)
            }
            
            if showReportedIndicator && message.flagCount > 0 && (viewModel.isReportedByMe || (message.isFlaggedByMe ?? false)) {
                Image(AmityIcon.Chat.redFlagIcon.imageResource)
                    .scaledToFit()
                    .padding(.bottom, 6)
                    .padding(.leading, 6)
                    .frame(width: 20, height: 20)
            } else {
                AmityChatMessageQuickReaction(message: message)
            }

            Text(dateFormat.string(from: message.createdAt ?? Date()))
                .modifier(StatusStyle(viewConfig: viewConfig))
                .isHidden(message.syncState != .synced)
                .accessibilityIdentifier(AccessibilityID.Chat.MessageList.bubbleTimestamp)
                .padding(.trailing, 4)
                

            Text(AmityLocalizedStringSet.Chat.statusSending.localizedString)
                .modifier(StatusStyle(viewConfig: viewConfig))
                .isHidden(message.syncState != .syncing)
                .accessibilityIdentifier(AccessibilityID.Chat.MessageList.bubbleSendingStatus)
        }
        .actionSheet(isPresented: $showSheet) {
            ActionSheet(
                title: Text(AmityLocalizedStringSet.Chat.deleteActionSheetTitle.localizedString),
                buttons: [
                    .destructive(Text(AmityLocalizedStringSet.Chat.deleteButton.localizedString)) {
                        messageAction.onDelete?(message)
                    },
                    .cancel()
                ]
            )
        }
    }
}

#if DEBUG
#Preview {
    MessageStatusView(message: MessageModel.preview, dateFormat: DateFormatter(), viewModel: ChatMessageBubbleViewModel(message: MessageModel.preview), messageAction: AmityMessageAction(onCopy: nil, onReply: nil, onDelete: nil, onReport: nil, onUnReport: nil))
}
#endif

extension MessageStatusView {
    
    struct StatusStyle: ViewModifier {
        
        let viewConfig: AmityViewConfigController
        
        func body(content: Content) -> some View {
            content
                .font(AmityTextStyle.captionSmall(.clear).getFont())
                .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                .padding(.leading, 6)
                .padding(.bottom, 8)
        }
    }
    
}
