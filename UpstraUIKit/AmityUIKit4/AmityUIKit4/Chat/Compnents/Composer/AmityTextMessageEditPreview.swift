//
//  AmityTextMessageEditPreview.swift
//  AmityUIKit4
//
//  Created by Nishan on 23/2/2567 BE.
//

import SwiftUI

struct AmityTextMessageEditPreview: View {
    
    let message: MessageModel
    let closeAction: DefaultTapAction
    
    var body: some View {
        
        HStack(spacing: 12) {
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Edit Message")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.white)
                Text(message.text)
                    .font(.system(size: 13, weight: .regular))
                    .lineLimit(1)
                    .foregroundColor(Color(hex: "EBECEF"))
            }
            .padding(.leading)
            
            Spacer()
            
            Button(action: {
                closeAction()
            }, label: {
                Image(AmityIcon.Chat.closeReply.imageResource)
            })
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 62)
        .background(Color(hex: "292B32")) // Light: F5F5F5
    }
}

#if DEBUG
#Preview {
    AmityTextMessageEditPreview(message: .init(id: UUID().uuidString, text: "I want to eat kfc tonight", type: .text, hasReaction: false, parentId: nil), closeAction: { })
}
#endif
