//
//  AmityLiveStreamChatFeed.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/26/25.
//

import Foundation
import SwiftUI
import AmitySDK

public struct AmityLiveStreamChatFeed: AmityComponentView {
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        .livestreamChatFeed
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @ObservedObject private var viewModel: AmityLiveStreamChatViewModel
    
    @Namespace private var topID
    @State private var animatingMessageIds: Set<String> = []
    @State private var lastMessageInViewport: Bool = true
    @State private var showDummyLastMessage: Bool = false
    @State private var lastMessageHeight: CGFloat = 0
    
    public init(viewModel: AmityLiveStreamChatViewModel, pageId: PageId? = nil) {
        self.pageId = pageId
        self.viewModel = viewModel
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .livestreamChatFeed))
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Attaching bottom sheet modifier to the ZStack will effect the new message appear animation
            // This modifier use fullScreenCover internally, and it will try to rebuild the entire view hierarchy when something inside view hierarchy is changed.
            backgroundOverlay
                .bottomSheet(isShowing: $viewModel.showBottomSheet.show, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor)) {
                    bottomSheetView
                }
            
            // This scroll view is upside down to match the chat feed direction and to support reverse pagination smoothly
            // Messages will be displayed in reverse order without needing to reverse the message data source
            // Note: need to arrange view hirearchy reversely to algin with the upside-down scroll view
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        Color.clear
                            .frame(maxHeight: showDummyLastMessage ? lastMessageHeight : 0)
                            .animation(.easeOut(duration: 0.6), value: showDummyLastMessage)
                            .isHidden(!showDummyLastMessage)
                        
                        ForEach(Array(viewModel.messages.enumerated()), id: \.element.uniqueId) { index, message in
                            getMessageBubble(message)
                                .id(message.uniqueId)
                                .modifier(NewMessageAnimationModifier(
                                    isAnimating: animatingMessageIds.contains(message.uniqueId)
                                ))
                                .scaleEffect(x: 1, y: -1)
                                .applyIf(index == 0) {
                                    $0.readSize { lastMessageHeight = $0.height }
                                }
                                .onAppear {
                                    if index == 0 {
                                        lastMessageInViewport = true
                                    }
                                }
                                .onDisappear {
                                    if index == 0 {
                                        lastMessageInViewport = false
                                    }
                                }
                        }
                        
                        Color.clear
                            .frame(height: 1)
                            .id(topID)
                            .onAppear {
                                guard !viewModel.messages.isEmpty else { return }
                                viewModel.loadPreviousMessages()
                            }
                    }
                }
                .padding(.horizontal, 16)
                .scaleEffect(x: 1, y: -1)
                .padding(.bottom, 12)
                .mask(fadeMask)
                .onChange(of: viewModel.messages.first?.uniqueId, perform: { _ in
                    guard lastMessageInViewport else { return }
                    handleMessagesUpdateAnimation(messages: viewModel.messages, proxy: proxy)
                })
                .onAppear {
                    handleMessagesUpdateAnimation(messages: viewModel.messages, proxy: proxy)
                }
            }
        }
        .updateTheme(with: viewConfig)
    }
    
    private var fadeMask: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.black.opacity(0),
                         Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 45)
            
            Color.black
        }
    }
    
    private var backgroundOverlay: some View {
        LinearGradient(
            colors: [Color.black.opacity(0),
                     Color.black.opacity(0.7),
                     Color.black.opacity(0.8),
                     Color.black],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func getMessageBubble(_ message: MessageModel) -> some View {
        HStack(alignment: message.syncState == .error ? .center : .top, spacing: 8) {
            // User name and message content
            VStack(alignment: .leading, spacing: 8) {
                Text(message.displayName)
                    .applyTextStyle(.captionSmall(Color(viewConfig.theme.baseColorShade1)))
                    .lineLimit(1)
                
                // Message content
                if message.isDeleted {
                    HStack(spacing: 6) {
                        Image(AmityIcon.trashBinIcon.getImageResource())
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fill)
                            .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                            .frame(width: 16, height: 18)
                            .offset(y: -1)
                        
                        Text("This message was deleted.")
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                    }
                } else {
                    Text(message.text)
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColor)))
                }
            }
            
            Spacer()
            
            // Action button
            if message.syncState == .error {
                Button {
                    showErrorActionSheet(message: message)
                } label: {
                    Image(AmityIcon.statusWarningIcon.getImageResource())
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 20)
                }
            } else if !message.isDeleted {
                Button {
                    viewModel.showBottomSheet.message = message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.showBottomSheet.show.toggle()
                    }
                } label: {
                    Image(AmityIcon.threeDotIcon.getImageResource())
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 16, height: 16)
                }
            }
        }
        .padding(.all, 12)
        .background(Color(UIColor(hex: "#636878")).opacity(0.3))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var bottomSheetView: some View {
        VStack(spacing: 0) {
            if viewModel.showBottomSheet.message?.isOwner ?? false {
                BottomSheetItemView(icon: AmityIcon.trashBinIcon.getImageResource(), text: AmityLocalizedStringSet.LiveChat.deleteMessage.localizedString, isDestructive: true)
                    .onTapGesture {
                        guard let message = viewModel.showBottomSheet.message else { return }
                        Task.runOnMainActor {
                            try await viewModel.deleteMessage(message.id)
                            viewModel.showBottomSheet.show.toggle()
                        }
                    }
            } else {
                let isFlagged = viewModel.showBottomSheet.message?.isFlaggedByMe ?? false
                let title = isFlagged ? AmityLocalizedStringSet.LiveChat.unreportMessage.localizedString : AmityLocalizedStringSet.LiveChat.reportMessage.localizedString
                BottomSheetItemView(icon: AmityIcon.flagIcon.getImageResource(), text: title)
                    .onTapGesture {
                        guard let message = viewModel.showBottomSheet.message else { return }
                        viewModel.showBottomSheet.show.toggle()
                        
                        AmityUserAction.perform(host: host) {
                            if isFlagged {
                                Task.runOnMainActor {
                                    try await viewModel.unflagMessage(message.id)
                                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.LiveChat.toastUnReportMessage.localizedString)
                                }
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    let page = AmityContentReportPage(type: .message(id: message.id)).environmentObject(viewConfig)
                                    let vc = AmitySwiftUIHostingNavigationController(rootView: page)
                                    vc.isNavigationBarHidden = true
                                    host.controller?.present(vc, animated: true)
                                }
                            }
                        }
                    }
            }
        }
        .padding(.bottom, 32)
    }
    
    private func showErrorActionSheet(message: MessageModel) {
        let alert = UIAlertController(title: "Your message wasn't sent", message: nil, preferredStyle: .actionSheet)
        alert.overrideUserInterfaceStyle = .dark
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            Task.runOnMainActor {
                try await viewModel.deleteMessage(message.id)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            host.controller?.present(alert, animated: true)
        }
    }
    
    private func handleMessagesUpdateAnimation(messages: [MessageModel], proxy: ScrollViewProxy) {
        // Check if new message was added
        if let firstMessage = messages.first,
           !animatingMessageIds.contains(firstMessage.uniqueId) {
            
            showDummyLastMessage = true
            
            // Animate the new message
            animatingMessageIds.insert(firstMessage.uniqueId)
            
            // Remove from animating set after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                animatingMessageIds.remove(firstMessage.uniqueId)
                showDummyLastMessage = false
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    proxy.scrollTo(firstMessage.uniqueId, anchor: .bottom)
                }
            }
        }
    }
}


private struct NewMessageAnimationModifier: ViewModifier {
    let isAnimating: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 0.9 : 1.0, anchor: .center)
            .opacity(isAnimating ? 0.7 : 1.0)
            .offset(y: isAnimating ? 25 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isAnimating)
    }
}
