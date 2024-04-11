//
//  AmityLiveChatHeader.swift
//  AmityUIKit4
//
//  Created by Nishan on 16/2/2567 BE.
//

import SwiftUI

public struct AmityLiveChatHeader: AmityComponentView {
    public var pageId: PageId?
    public var id: ComponentId {
        return .liveChatHeader
    }
    
    @StateObject var networkMonitor = NetworkMonitor()
    @StateObject var viewModel: AmityLiveChatHeaderViewModel

    public init(viewModel: AmityLiveChatPageViewModel, pageId: PageId? = .liveChatPage) {
        self.pageId = pageId
        self._viewModel = StateObject(wrappedValue: viewModel.header)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                
                AmityAvatarView(avatarURL: viewModel.avatarURL)
                    .accessibilityIdentifier(AccessibilityID.Chat.LiveChatHeader.avatar)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "FFFFFF"))
                        .lineLimit(1)
                        .accessibilityIdentifier(AccessibilityID.Chat.LiveChatHeader.headerTitle)
                    
                    ZStack {
                        AmityMemberCountView(memberCount: viewModel.memberCount)
                            .opacity(networkMonitor.isConnected ? 1 : 0)
                            .accessibilityIdentifier(AccessibilityID.Chat.LiveChatHeader.memberCount)
                        
                        AmityConnectivityView()
                            .opacity(networkMonitor.isConnected ? 0 : 1)
                            .accessibilityIdentifier(AccessibilityID.Chat.LiveChatHeader.connectivity)
                    }
                    .padding(.top, 2)
                }
                .padding(.leading, 8)
                
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            
            Rectangle()
                .fill(Color(UIColor(hex: "#292B32"))) // Light Theme: EBECEF
                .frame(height: 1)
        }
        .background(Color(hex: "191919"))
        .onAppear {
            viewModel.loadChannelInfo()
        }
    }
}

#if DEBUG
#Preview {
    AmityLiveChatHeader(viewModel: AmityLiveChatPageViewModel(channelId: "1234"))
}
#endif

public extension AmityLiveChatHeader {
    
    // Move these elements out of extension if its reused anywhere else.
    struct AmityMemberCountView: AmityElementView {
        public var pageId: PageId?
        public var componentId: ComponentId?
        public var id: ElementId {
            return .memberCount
        }
        
        private let memberCount: Int
        
        public init(pageId: PageId? = nil, componentId: ComponentId? = nil, memberCount: Int) {
            self.pageId = pageId
            self.componentId = componentId
            self.memberCount = memberCount
        }
        
        public var body: some View {
            HStack(alignment: .center, spacing: 0) {
                Image(AmityIcon.Chat.membersCount.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                
                Text("\(memberCount.formattedCountString) members")
                    .foregroundColor(Color(hex: "EBECEF"))
                    .font(.system(size: 13))
                    .padding(.leading, 4)
                
                Spacer()
            }
        }
    }
    
    struct AmityConnectivityView: AmityElementView {
        
        public var pageId: PageId?
        public var componentId: ComponentId?
        
        public var id: ElementId {
            return .connectivity
        }
        
        public init(pageId: PageId? = nil, componentId: ComponentId? = nil) {
            self.pageId = pageId
            self.componentId = componentId
        }
        
        public var body: some View {
            HStack(alignment: .center, spacing: 0) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                    .accentColor(Color(hex: "FFFFFF"))
                    .scaleEffect(0.8)
                
                Text(AmityLocalizedStringSet.Chat.connectivityStatusWaiting.localizedString)
                    .foregroundColor(Color(hex: "EBECEF"))
                    .font(.system(size: 13))
                    .padding(.leading, 4)
                
                Spacer()
            }
        }
    }
    
    struct AmityAvatarView: AmityElementView {
        
        public var pageId: PageId?
        public var componentId: ComponentId?
        
        public var id: ElementId {
            return .avatar
        }
        
        let avatarURL: URL?
        
        public init(pageId: PageId? = nil, componentId: ComponentId? = nil, avatarURL: URL?) {
            self.pageId = pageId
            self.componentId = componentId
            self.avatarURL = avatarURL
        }
        
        public var body: some View {
            AsyncImage(placeholder: AmityIcon.Chat.chatAvatarProfilePlaceholder.imageResource, url: avatarURL, contentMode: .fill)
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        }
    }
}
