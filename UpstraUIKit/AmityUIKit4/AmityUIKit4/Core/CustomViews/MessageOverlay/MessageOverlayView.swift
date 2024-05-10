//
//  MessageOverlayView.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 3/5/2567 BE.
//

import SwiftUI

struct MessageOverlayView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController

    @State var isMenuActive: Bool = true
    var message: MessageModel
    let messageAction: AmityMessageAction
    let namespace: Namespace.ID
    let dismissAction: () -> Void
    
    @State var animateScale = false
    
    public var body: some View {
        VStack (alignment: .leading, spacing: 8) {
            
            AmityLiveChatMessageReactionPicker(message: message, dismissAction: dismissAction)
                .scaleEffect(animateScale ? 1 : 0, anchor: .bottomLeading)
            
            HStack {
                textContent
            }
            .matchedGeometryEffect(id: message.id, in: namespace)
            .modifier(LiveChatMessageBubble(isBubbleEnabled: true, message: message, viewModel: LiveChatMessageBubbleViewModel(message: message)))
            .padding(.top, 4)
            .padding(.trailing, 6)
            .scaleEffect(animateScale ? 1.05 : 0, anchor: .leading)
            
            
            MessageActionView(message: message, messageAction: messageAction, dismissAction: dismissAction)
            .background(Color(viewConfig.theme.baseColorShade4))
            .cornerRadius(12)
            .frame(width: 243)
            .scaleEffect(animateScale ? 1 : 0, anchor: .topLeading)
            .onAppear(perform: {

                withAnimation(.interpolatingSpring(stiffness: 170, damping: 13)) {
                    animateScale = true
                }
            })
            .onDisappear {
                withAnimation {
                    animateScale = false
                }
            }
            
        }
        .opacity(isMenuActive ? 1 : 0)
    }
    
    @ViewBuilder
    var textContent: some View {
        if #available(iOS 15, *) {
            let attributedText = TextHighlighter.getAttributedText(from: message)
            Text(attributedText)
        } else {
            Text(message.text)
        }
    }
}
