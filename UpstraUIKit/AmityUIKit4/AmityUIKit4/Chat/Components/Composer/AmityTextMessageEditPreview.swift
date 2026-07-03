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
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    var body: some View {
        
        HStack(spacing: 12) {
            
            Text(AmityLocalizedStringSet.Chat.Bubble.editing.localizedString)
                .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColor)))
            
            Spacer()
            
            Button(action: {
                closeAction()
            }, label: {
                Image(AmityIcon.Chat.closeReply.imageResource)
                    .frame(width: 24, height: 24)
            })
        }
        .padding(EdgeInsets(top: 15, leading: 16, bottom: 15, trailing: 12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 48)
        .background(Color(viewConfig.theme.baseColorShade4))
    }
}

#if DEBUG
#Preview {
    AmityTextMessageEditPreview(message: .init(id: UUID().uuidString, text: "I want to eat kfc tonight", type: .text, hasReaction: false, parentId: nil), closeAction: { }) // l10n:ok preview mock data
}
#endif
