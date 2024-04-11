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
    
    private let config: Configuration
        
    public init(viewModel: AmityLiveChatPageViewModel, pageId: PageId? = .liveChatPage) {
        self.pageId = pageId
        self.chatViewModel = viewModel
        self._messageListViewModel = StateObject(wrappedValue: viewModel.messageList)
        self.config = Configuration.init(pageId: pageId, componentId: .messageList)
    }
    
    public var body: some View {
        ZStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    // need adjust padding
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
                                    // Remove this explict unwrap later.
                                    AmityLiveChatMessageSenderView(message: message, messageAction: messageListViewModel.messageAction!)
                                } else {
                                    AmityLiveChatMessageReceiverView(message: message, messageAction: messageListViewModel.messageAction!)
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
            .background(Color(hex: config.color.background).ignoresSafeArea(.all))
            .alert(isPresented: $showDeleteAlert, content: {
                Alert(title: Text(AmityLocalizedStringSet.Chat.deleteAlertTitle.localizedString), message: Text(AmityLocalizedStringSet.Chat.deleteAlertMessage.localizedString), primaryButton: .cancel(), secondaryButton: .destructive(Text(AmityLocalizedStringSet.Chat.deleteButton.localizedString), action: {
                    Task {
                        do {
                            try await messageListViewModel.deleteMessage(messageId: deletingMessageId)
                        } catch {
                            Log.chat.debug("Error while deleting text message \(error.localizedDescription)")
                            chatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.toastDeleteErrorMessage.localizedString, style: .warning)                            
                        }
                    }
                }))
            })
            .onAppear {
                messageListViewModel.queryMessages()
            }
            .opacity(messageListViewModel.initialQueryState == .success ? 1 : 0)
            
            VStack(spacing: 0) {
                AmityEmptyStateView(configuration: AmityEmptyStateView.EmptyStateConfiguration(image: AmityIcon.Chat.greyRetryIcon.rawValue, title: nil, subtitle: AmityLocalizedStringSet.Chat.errorLoadingChat
                    .localizedString, tapAction: {
                        
                        messageListViewModel.queryMessages()
                    }))
                .accessibilityIdentifier(AccessibilityID.Chat.MessageList.emptyStateContainer)

            }
            .opacity(messageListViewModel.initialQueryState == .error ? 1 : 0)
        }
        .onAppear {
            let defaultActions = AmityMessageAction { message in
                UIPasteboard.general.string = message.text
                chatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.toastCopied.localizedString, style: .success)
            } onReply: { message in
                chatViewModel.composer.action = .reply(message)
            } onDelete: { message in
                deletingMessageId = message.id
                showDeleteAlert = true
            }
            
            messageListViewModel.messageAction = defaultActions
        }
    }
    
    
    struct Configuration: UIKitConfigurable {
        
        var pageId: PageId?
        var componentId: ComponentId?
        var elementId: ElementId?
        
        var color: ColorConfig = .init()
        
        init(pageId: PageId?, componentId: ComponentId?) {
            self.pageId = pageId
            self.componentId = nil
            self.elementId = nil
        }
        
        struct ColorConfig {
            let background: String = "191919"
        }
    }
}

#if DEBUG
#Preview {
    AmityLiveChatMessageList(viewModel: AmityLiveChatPageViewModel(channelId: ""))
}
#endif

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct UpsideDown: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: 180))
            .scaleEffect(x: -1.0, y: 1.0, anchor: .center)
    }
}
