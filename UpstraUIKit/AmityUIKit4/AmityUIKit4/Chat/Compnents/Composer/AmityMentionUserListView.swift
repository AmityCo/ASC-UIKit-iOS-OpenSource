//
//  AmityMentionUserListView.swift
//  AmityUIKit4
//
//  Created by Nishan on 25/3/2567 BE.
//

import SwiftUI

struct AmityMentionUserListView: View {
        
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @Binding var mentionedUsers: [AmityMentionUserModel]
    let selection: (AmityMentionUserModel) -> Void
    let paginate: () -> Void
    
    var listHeight: CGFloat {
        return mentionedUsers.count < 3 ? CGFloat(mentionedUsers.count) * 52.0 : 156
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(mentionedUsers.enumerated()), id: \.element.userId) { index, item in
                    
                    AmityMentionUserItemView(user: item, action: {
                        selection(item)
                    })
                    .onAppear {
                        if index == mentionedUsers.count - 1  {
                            paginate()
                        }
                    }
                }
            }
        }
        .frame(height: listHeight)
    }
    
    struct Configuration: UIKitConfigurable {
        var pageId: PageId?
        var componentId: ComponentId?
        var elementId: ElementId?
    }
}

#if DEBUG
#Preview {
    AmityMentionUserListView(mentionedUsers: .constant([AmityMentionUserModel.channelMention]), selection: { _ in }, paginate: { })
}
#endif

struct AmityMentionUserItemView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    let user: AmityMentionUserModel
    let action: DefaultTapAction?
    
    var body: some View {
        Button(action: {
            action?()
        }, label: {
            HStack(spacing: 0) {
                AsyncImage(placeholder: user.isChannelMention ? AmityIcon.Chat.mentionAll.imageResource : AmityIcon.Chat.chatAvatarPlaceholder.imageResource, url: URL(string: user.avatarURL))
                    .frame(width: 28, height: 28)
                    .clipped()
                    .clipShape(Circle())
                    .accessibilityIdentifier(AccessibilityID.Chat.MentionList.userAvatar)
                
                Text(user.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.leading, 8)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .accessibilityIdentifier(AccessibilityID.Chat.MentionList.userDisplayName)
                
                if user.isBrand {
                    Image(AmityIcon.brandBadge.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .padding(.leading, 4)
                }
                
                Spacer()
                
                if user.isChannelMention {
                    Text(AmityLocalizedStringSet.Chat.mentionEveryone.localizedString)
                        .font(.system(size: 13))
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .padding(.trailing, 8)
                }
            }
        })
        .frame(height: 52)
        .padding(.horizontal, 10)
        //.padding(10) // Height for each row is 52
    }
}
