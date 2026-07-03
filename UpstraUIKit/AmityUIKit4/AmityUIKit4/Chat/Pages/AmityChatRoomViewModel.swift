//
//  AmityChatRoomViewModel.swift
//  AmityUIKit4
//

import SwiftUI
import Combine

@MainActor
public class AmityChatRoomViewModel: ObservableObject {
    
    let channelId: String
    let aroundMessageId: String?
    var channelDisplayName: String = ""
    
    lazy var composer = AmityMessageComposerViewModel(subChannelId: channelId)
    lazy var messageList = AmityChatMessageListViewModel(subChannelId: channelId, aroundMessageId: aroundMessageId)
    
    var toastMessage = ToastMessage(message: "", style: .warning)
    @Published var showToast: Bool = false
    
    struct ToastMessage {
        let message: String
        let style: ToastStyle
    }
    
    public init(channelId: String, aroundMessageId: String? = nil) {
        self.channelId = channelId
        self.aroundMessageId = aroundMessageId
    }
    
    func showToastMessage(message: String, style: ToastStyle) {
        toastMessage = ToastMessage(message: message, style: style)
        showToast = true
    }
}
