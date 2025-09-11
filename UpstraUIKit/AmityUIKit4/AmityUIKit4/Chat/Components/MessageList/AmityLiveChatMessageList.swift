//
//  AmityLiveChatMessageList.swift
//  AmityUIKit4
//
//  Created by Nishan on 16/2/2567 BE.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityLiveChatMessageList: AmityComponentView {
    // Identifiers
    public var pageId: PageId?
    public var id: ComponentId {
        return .messageList
    }
    
    @StateObject var messageListViewModel: AmityMessageListViewModel
    var chatViewModel: AmityLiveChatPageViewModel
    
    @State private var deletingMessageId: String = ""
    @State private var showDeleteAlert: Bool = false
    @StateObject private var viewConfig: AmityViewConfigController
    
    @State private var showReactionSheet = false
        
    public init(viewModel: AmityLiveChatPageViewModel, pageId: PageId? = .liveChatPage) {
        self.pageId = pageId
        self.chatViewModel = viewModel
        self._messageListViewModel = StateObject(wrappedValue: viewModel.messageList)
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .messageList))
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        LazyVStack (spacing: 8) {
                            ForEach(Array(messageListViewModel.messages.enumerated()), id: \.element.id) { index, message in
                                if let firstMessage = messageListViewModel.messages.first, message.id == firstMessage.id, messageListViewModel.isPaginationAvailable() {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .padding(.vertical, 8)
                                        .foregroundColor(.white)
                                }
                                
                                Group {
                                    if message.isOwner {
                                        AmityLiveChatMessageSenderView(message: message, messageAction: messageListViewModel.messageAction)
                                    } else {
                                        AmityLiveChatMessageReceiverView(message: message, messageAction: messageListViewModel.messageAction)
                                    }
                                }
                                .id(message.id)
                                .padding(.bottom, message.id == messageListViewModel.messages.last?.id ? 8 : 0)
                                .accessibilityIdentifier(AccessibilityID.Chat.MessageList.bubbleContainer)
                            }
                        }
                        .padding(.top, 8)
                        .onChange(of: messageListViewModel.messages.last?.id) { _ in
                            
                            withAnimation {
                                if let id = messageListViewModel.messages.last?.id {
                                    scrollViewProxy.scrollTo(id)
                                }
                            }
                        }
                        .background(GeometryReader { geometry in
                            Color.clear.preference(key: ViewOffsetKey.self,
                                                   value: -geometry.frame(in: .named("scroll")).origin.y)
                            
                        })
                        .onPreferenceChange(ViewOffsetKey.self) { value in
                            if value < 0 {
                                // Set pagination target id
                                messageListViewModel.loadMoreMessages()
                            }
                        }
                        .onAppear {
                            if let id = messageListViewModel.messages.last?.id {
                                scrollViewProxy.scrollTo(id, anchor: .bottom)
                            }
                        }
                    }
                    .onTapGesture {
                        hideKeyboard()
                    }
                    .coordinateSpace(name: "scroll")
                    .onChange(of: messageListViewModel.pagination.pagination, perform: { value in
                        // Scroll to last anchor which trigger pagination
                        if let anchor = messageListViewModel.pagination.anchor {
                            scrollViewProxy.scrollTo(anchor, anchor: .top)
                        }
                    })
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle()
                        .fill(Color(viewConfig.theme.secondaryColor))
                        .frame(height: 1)
                        .padding(.bottom, 16)
                    
                    HStack(spacing: 0) {
                        Image(AmityIcon.Chat.mutedIcon.imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding(.horizontal, 16)
                        Text(messageListViewModel.muteState.localizedString)
                            .padding(.trailing, 16)
                            .font(.system(size: 15))
                            .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                    }
                    
                }
                .padding(.bottom, 16)
                .opacity(messageListViewModel.initialQueryState != .success ? 0 : 1)
                .isHidden(messageListViewModel.muteState == .none || messageListViewModel.hasModeratorPermission)
            }
            .alert(isPresented: $showDeleteAlert, content: {
                Alert(title: Text(AmityLocalizedStringSet.Chat.deleteAlertTitle.localizedString), message: Text(AmityLocalizedStringSet.Chat.deleteAlertMessage.localizedString), primaryButton: .cancel(), secondaryButton: .destructive(Text(AmityLocalizedStringSet.Chat.deleteButton.localizedString), action: {
                    messageListViewModel.deleteMessage(messageId: deletingMessageId)
                }))
            })
            .onAppear {
                messageListViewModel.queryMessages()
            }
            .opacity(messageListViewModel.initialQueryState == .success ? 1 : 0)
            
            /// Display general empty state
            AmityEmptyStateView(configuration: AmityEmptyStateView.Configuration(image: AmityIcon.Chat.greyRetryIcon.rawValue, title: nil, subtitle: AmityLocalizedStringSet.Chat.errorLoadingChat
                .localizedString, tapAction: {
                    
                    messageListViewModel.queryMessages()
                    
                }))
            .accessibilityIdentifier(AccessibilityID.Chat.MessageList.emptyStateContainer)
            .opacity(messageListViewModel.initialQueryState == .error ? 1 : 0)
            
            /// Display banned empty state
            AmityEmptyStateView(configuration: AmityEmptyStateView.Configuration(image: AmityIcon.Chat.emptyStateMessage.rawValue, title: AmityLocalizedStringSet.Chat.errorBannedTitleChat
                .localizedString, subtitle: AmityLocalizedStringSet.Chat.errorBannedSubTitleInChat
                .localizedString, iconSize: CGSize(width: 48, height: 48), tapAction: nil))
            .accessibilityIdentifier(AccessibilityID.Chat.MessageList.emptyStateContainer)
            .opacity(messageListViewModel.initialQueryState == .banned ? 1 : 0)
        }
        .sheet(isPresented: $showReactionSheet, content: {
            if let selectedMessage = messageListViewModel.selectedMessage?.message {
                AmityReactionList(message: selectedMessage, pageId: self.pageId)
            }
        })
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea(.all))
        .onReceive(messageListViewModel.$toastState, perform: { state in
            if let state {
                chatViewModel.showToastMessage(message: state.message, style: state.style)
            }
        })
        .onAppear {
            setupMessageActions()
        }
        .updateTheme(with: viewConfig)
    }
    
    func setupMessageActions() {
        let defaultActions = AmityMessageAction(onCopy: { message in
            UIPasteboard.general.string = message.text
            chatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.toastCopied.localizedString, style: .success)
        },onReply: { message in
            chatViewModel.composer.action = .reply(message)
        },onDelete: { message in
            deletingMessageId = message.id
            if message.syncState == .error {
                messageListViewModel.deleteMessage(messageId: deletingMessageId)
            } else {
                showDeleteAlert = true
            }
        },onReport: { message in
            messageListViewModel.reportMessage(messageId: message.id)
        },onUnReport: { message in
            messageListViewModel.unReportMessage(messageId: message.id)
        })
        
        defaultActions.showReaction = { message in
            self.messageListViewModel.selectedMessage = message
            self.showReactionSheet.toggle()
        }
        
        messageListViewModel.messageAction = defaultActions
    }
}

#if DEBUG
#Preview {
    AmityLiveChatMessageList(viewModel: AmityLiveChatPageViewModel(channelId: ""))
}
#endif
