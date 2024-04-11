//
//  AmityLiveChatPageViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan on 3/4/2567 BE.
//

import SwiftUI
import Combine

public class AmityLiveChatPageViewModel: ObservableObject {
    
    let channelId: String
    
    lazy var header = AmityLiveChatHeaderViewModel(channelId: channelId)
    lazy var composer = AmityMessageComposerViewModel(subChannelId: channelId)
    lazy var messageList = AmityMessageListViewModel(subChannelId: channelId)
    
    var toastMessage = ToastMessage(message: "", style: .warning)
    @Published var showToast: Bool = false
    
    struct ToastMessage {
        let message: String
        let style: ToastStyle
    }
    
    public init(channelId: String) {
        self.channelId = channelId
    }
    
    func showToastMessage(message: String, style: ToastStyle ) {
        toastMessage = ToastMessage(message: message, style: style)
        showToast = true
    }
}
