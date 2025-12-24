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
    
    private var placeholder: String {
        AmityLocalizedStringSet.Social.livestreamChatPlaceholder.localizedString
    }
    private let maxCharCount: Int = 200
    
    public init(viewModel: AmityLiveStreamChatViewModel, pageId: PageId? = nil) {
        self.viewModel = viewModel
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .livestreamChatComposeBar))
    }
    
    public var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            switch viewModel.composeBarState {
            case .normal, .disabled:
                inputView
                    .allowsHitTesting(!AmityUIKitManagerInternal.shared.isGuestUser)
                rightButton

            case .muted:
                getInfoView(icon: AmityIcon.LiveStream.disabledChatIcon.imageResource, text: AmityLocalizedStringSet.Social.livestreamChatMutedMessage.localizedString)
                Spacer()
                rightButton
                
            case .readOnly:
                getInfoView(icon: AmityIcon.LiveStream.disabledChatIcon.imageResource, text: AmityLocalizedStringSet.Social.livestreamChatReadonlyMessage.localizedString)
                Spacer()
                rightButton
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
                        Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.livestreamChatSendFailedMessage.localizedString, bottomPadding: 60)
                    }
                    
                    viewModel.messageInput.removeAll()
                    hideKeyboard()
                }
            } label: {
                Image(AmityIcon.Chat.sendActionIcon.imageResource)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .padding(.bottom, 8)
            }
        } else if viewModel.isStreamer && viewModel.participantRole != .viewer {
            // Only host can invite co-host
            if viewModel.participantRole == .host {
                Button {
                    viewModel.inviteCoHostAction?()
                } label: {
                    Image(AmityIcon.inviteUserIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .circularBackground(radius: 40, color: Color(viewConfig.defaultDarkTheme.baseColorShade4))
                }
            }
            
            Button {
                viewModel.isMicOn.toggle() // Update UI state immediately
                viewModel.toggleMicAction?()
            } label: {
                Image(viewModel.isMicOn ? AmityIcon.LiveStream.mic.imageResource : AmityIcon.LiveStream.unmuteMic.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .circularBackground(radius: 40, color: Color(viewConfig.defaultDarkTheme.baseColorShade4))
            }
            
            Button {
                viewModel.swapCameraAction?()
            } label: {
                Image(AmityIcon.LiveStream.switchCamera.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .circularBackground(radius: 40, color: Color(viewConfig.defaultDarkTheme.baseColorShade4))
            }
        } else {
            Image(AmityIcon.Reaction.like.imageResource)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
                .padding(.bottom, 8)
                .onTapGesture {
                    let like = AmityLiveReactionModel(reactionName: "like", referenceId: viewModel.room.post?.postId ?? "", streamId: viewModel.room.roomId)
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
                .disableNewlines(true)
                .onChange(of: viewModel.messageInput) { newValue in
                    // this logic is intentionally added here not to change the behavior of text editor
                    if newValue.contains("\n") {
                        hideKeyboard()
                    }
                }
        } else {
            ExpandableTextEditorView(isTextEditorFocused: .constant(true), input: $viewModel.messageInput)
                .placeholder(placeholder)
                .font(AmityTextStyle.body(.white).getFont())
                .maxCharCount(maxCharCount)
                .lineLimit(1)
                .disableNewlines(true)
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
        .padding(.bottom, 12)
    }
}
