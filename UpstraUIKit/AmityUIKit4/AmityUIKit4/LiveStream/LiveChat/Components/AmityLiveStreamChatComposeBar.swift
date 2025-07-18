//
//  AmityLiveStreamChatComposeBar.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/27/25.
//

import Foundation
import SwiftUI

public struct AmityLiveStreamChatComposeBar: AmityComponentView {
    public var pageId: PageId?
    
    public var id: ComponentId {
        .livestreamChatComposeBar
    }
    
    @ObservedObject private var viewModel: AmityLiveStreamChatViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    
    private let placeholder: String = "Chat..."
    private let maxCharCount: Int = 200
    
    public init(viewModel: AmityLiveStreamChatViewModel, pageId: PageId? = nil) {
        self.viewModel = viewModel
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .livestreamChatComposeBar))
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            switch viewModel.composeBarState {
            case .normal:
                inputView
                rightButton

            case .muted:
                getInfoView(icon: AmityIcon.LiveStream.disabledChatIcon.imageResource, text: "You have been muted.")
                Spacer()
                rightButton
                
            case .readOnly:
                getInfoView(icon: AmityIcon.LiveStream.disabledChatIcon.imageResource, text: "This live stream is now read-only.")
                Spacer()
                rightButton
                
            case .disabled:
                getInfoView(text: "Join community to interact with live stream.")
            }
        }
    }
    
    /// Right button that shows different actions based on the state of the chat compose bar.
    /// If the text editor is focused, it shows a send button.
    /// If the user is a streamer, it shows a flip camera button.
    /// Otherwise, it shows a like reaction button.
    @ViewBuilder
    private var rightButton: some View {
        if viewModel.isTextEditorFocused {
            Button {
                Task.runOnMainActor {
                    do {
                        try await viewModel.sendMessage()
                    } catch {
                        Toast.showToast(style: .warning, message: "Failed to send message. Please try again.")
                    }
                    
                    viewModel.messageInput.removeAll()
                    hideKeyboard()
                }
            } label: {
                Image(AmityIcon.Chat.sendActionIcon.imageResource)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            }
        } else if viewModel.isStreamer {
            Button {
                viewModel.swapCameraAction?()
            } label: {
                Image(AmityIcon.flipCameraIcon.imageResource)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            }
        } else {
            Image(AmityIcon.Reaction.like.imageResource)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .onTapGesture {
                    let like = AmityLiveReactionModel(reactionName: "like", referenceId: viewModel.stream.post?.postId ?? "", streamId: viewModel.stream.streamId)
                    viewModel.liveReactionViewModel.addReaction(like)
                }
                .onLongPressGesture {
                    ImpactFeedbackGenerator.impactFeedback(style: .medium)
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.showReactionBar.toggle()
                    }
                }
        }
    }
    
    @ViewBuilder
    private var inputView: some View {
        if #available(iOS 15.0, *) {
            FocusableTextEditorView(input: $viewModel.messageInput, focus: $viewModel.isTextEditorFocused)
                .placeholder(placeholder)
                .font(AmityTextStyle.body(.white).getFont())
                .maxCharCount(maxCharCount)
                .lineLimit(1)
        } else {
            ExpandableTextEditorView(isTextEditorFocused: .constant(true), input: $viewModel.messageInput)
                .placeholder(placeholder)
                .font(AmityTextStyle.body(.white).getFont())
                .maxCharCount(maxCharCount)
        }
    }
    
    @ViewBuilder
    private func getInfoView(icon: ImageResource? = nil, text: String) -> some View {
        HStack(spacing: 10) {
            if let icon {
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 16)
                    .padding(.leading, 12)
            }
        
            Text(text)
                .applyTextStyle(.body(Color(viewConfig.theme.secondaryColor.blend(.shade2))))
        }
    }
}
