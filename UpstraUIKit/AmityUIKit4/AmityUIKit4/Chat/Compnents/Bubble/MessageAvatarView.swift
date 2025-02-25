//
//  MessageAvatarView.swift
//  AmityUIKit4
//
//  Created by Nishan on 19/2/2567 BE.
//

import SwiftUI

struct MessageAvatarView: View {
    
    let message: MessageModel
    let placeholderIcon: ImageResource
    
    var body: some View {
        AsyncImage(placeholder: placeholderIcon, url: message.avatarURL, contentMode: .fill)
            .frame(width: 32, height: 32)
            .clipped()
            .clipShape(Circle())
        
    }
}

#if DEBUG
#Preview {
    MessageAvatarView(message: MessageModel.preview, placeholderIcon: AmityIcon.defaultCommunity.getImageResource())
}
#endif
