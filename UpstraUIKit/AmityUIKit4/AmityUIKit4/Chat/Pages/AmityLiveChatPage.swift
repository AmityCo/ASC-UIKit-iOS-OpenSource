//
//  AmityLiveChatPage.swift
//  AmityUIKit4
//
//  Created by Nishan on 16/2/2567 BE.
//

import SwiftUI
import Combine
import AmitySDK

public struct AmityLiveChatPage: AmityPageView {
    
    public var id: PageId {
        return .liveChatPage
    }
    
    @StateObject var viewModel: AmityLiveChatPageViewModel
    @StateObject var messageViewModel: AmityMessageListViewModel
    
    public init(channelId: String) {
        let viewModel = AmityLiveChatPageViewModel(channelId: channelId)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._messageViewModel = StateObject(wrappedValue: viewModel.messageList)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            AmityLiveChatHeader(viewModel: viewModel)
                .accessibilityIdentifier(AccessibilityID.Chat.LiveChatHeader.container)
            
            ZStack {
                // List & composer
                VStack(spacing: 0) {
                    AmityLiveChatMessageList(viewModel: viewModel, pageId: .liveChatPage)
                        .accessibilityIdentifier(AccessibilityID.Chat.MessageList.container)                    

                    // Hide only in case of error in first load
                    AmityLiveChatMessageComposeBar(viewModel: viewModel)
                        .isHidden(messageViewModel.initialQueryState != .success)
                        .accessibilityIdentifier(AccessibilityID.Chat.MessageComposer.container)
                }
                .showToast(isPresented: $viewModel.showToast, style: viewModel.toastMessage.style, message: viewModel.toastMessage.message, bottomPadding: 80)
                
                // Show this indicator only on first load.
                LoadingIndicator
                    .opacity(messageViewModel.initialQueryState == .loading ? 1 : 0)
            }
        }
    }
    
    @ViewBuilder
    var LoadingIndicator: some View {
        VStack {
            Spacer()
            ToastView(message: AmityLocalizedStringSet.Chat.toastLoading.localizedString, style: .loading)
                .padding(.bottom, 24)
        }
    }
}

#if DEBUG
#Preview {
    AmityLiveChatPage(channelId: "")
}
#endif

enum BubbleAlignment {
    case left
    case right
}
