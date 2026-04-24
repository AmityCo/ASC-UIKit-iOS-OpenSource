//
//  LiveRoomGlobalTargetView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/25/25.
//

import SwiftUI
import AmitySDK

// NOTE:
// Retrieve EVENT model based on eventId instead of accessing it through target community. In new sdk, event object is not attached to post or room.
struct LiveRoomGlobalTargetView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    private let post: AmityPostModel
    private var isEventRoom: Bool = false
    
    @StateObject var viewModel = LiveRoomGlobalTargetViewModel()
    
    init(post: AmityPostModel) {
        self.post = post
    }
    
    var body: some View {
        getStoryView(avatar: getAvatar(),
                     cornerAvatar: getCornerAvatar(),
                     name: getName())
        .onAppear {
            viewModel.loadEvent(eventId: post.eventId)
        }
    }
    
    private func getStoryView(avatar: (URL?, ImageResource),
                              cornerAvatar: (URL?, String),
                              name: String) -> some View {
        return VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 2.0)
                    .fill(Color(hex: "#FF305A"))
                    .frame(width: 64, height: 64)
                    .accessibilityIdentifier(AccessibilityID.Story.AmityStoryTabComponent.storyRingView)
                
                AsyncImage(placeholder: avatar.1, url: avatar.0)
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .accessibilityIdentifier(AccessibilityID.Story.AmityStoryTabComponent.avatarImageView)
                
                AmityUserProfileImageView(displayName: cornerAvatar.1, avatarURL: cornerAvatar.0)
                    .frame(width: 22.0, height: 22.0)
                    .clipShape(Circle())
                    .padding(.all, 2)
                    .background(Color.white)
                    .clipShape(Circle())
                    .offset(x: 22, y: 22)
            }
            .overlay(liveBadge.offset(y: -3), alignment: .top)
            
            HStack(spacing: 0) {
                Image(AmityIcon.lockBlackIcon.getImageResource())
                    .renderingMode(.template)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .scaledToFit()
                    .frame(width: 20, height: 12)
                    .offset(y: -1)
                    .isHidden(post.targetCommunity?.isPublic ?? true)
                    
                Text(name)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColor)))
                    .frame(height: 20, alignment: .leading)
                    .accessibilityIdentifier(AccessibilityID.Story.AmityStoryTabComponent.targetNameTextView)
            }
        }
    }
    
    @ViewBuilder
    private var liveBadge: some View {
        Text("LIVE")
            .applyTextStyle(.custom(10, .semibold, .white))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color(hex: "#FF305A"))
            .cornerRadius(4, corners: .allCorners)
            .padding(.all, 2)
            .background(Color.white)
            .cornerRadius(4, corners: .allCorners)
    }
    
    private func getAvatar() -> (url: URL?, placeholder: ImageResource) {
        let fileURL = viewModel.event?.coverImage?.mediumFileURL ?? post.targetCommunity?.avatar?.mediumFileURL
        let avatarURL = URL(string: (fileURL ?? ""))
        let placeholder = viewModel.event != nil ? AmityIcon.eventImagePlaceholder.imageResource : AmityIcon.defaultCommunity.imageResource
                            
        return (avatarURL, placeholder)
    }
    
    private func getCornerAvatar() -> (url: URL?, displayName: String) {
        let avatarURL = URL(string: post.room?.creator?.avatar?.mediumFileURL ?? "")
        let name = post.room?.creator?.displayName ?? "Unknown"
        return (avatarURL, name)
    }
    
    private func getName() -> String {
        let name = viewModel.event?.title ?? post.targetCommunity?.displayName
        return name ?? "Unknown"
    }
}

class LiveRoomGlobalTargetViewModel: ObservableObject {
    
    @Published var event: AmityEvent?
    
    private let eventRepo = AmityEventRepository()
    private var token: AmityNotificationToken?
    
    func loadEvent(eventId: String?) {
        guard let eventId else { return }
        
        token = eventRepo.getEvent(id: eventId).observe{ liveObject, error in
            
            if let snapshot = liveObject.snapshot {
                self.event = snapshot
                self.token?.invalidate()
                return
            }
        }
    }
}
