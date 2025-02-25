//
//  StoryTargetView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/21/23.
//

import SwiftUI

struct StoryTargetView<Content: View>: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    let componentId: ComponentId
    @ViewBuilder private let cornerImage: () -> Content
    @ObservedObject private var storyTarget: AmityStoryTargetModel
    private let storyTargetName: String
    private let hideLockIcon: Bool
    
    init(componentId: ComponentId, storyTarget: AmityStoryTargetModel, storyTargetName: String? = nil, hideLockIcon: Bool, @ViewBuilder cornerImage: @escaping () -> Content) {
        self.componentId = componentId
        self.storyTarget = storyTarget
        self.hideLockIcon = hideLockIcon
        self.cornerImage = cornerImage
        
        if let storyTargetName {
            self.storyTargetName = storyTargetName
        } else {
            self.storyTargetName = storyTarget.targetName
        }
    }
    
    var body: some View {
        getStoryView(avatar: storyTarget.avatar,
                     name: storyTargetName,
                     showRing: storyTarget.hasUnseenStory,
                     animateRing: storyTarget.hasSyncingStory,
                     showErrorRing: storyTarget.hasFailedStory,
                     cornerImage: cornerImage)
    }
    
    private func getStoryView(avatar: URL?, name: String, showRing: Bool, animateRing: Bool, showErrorRing: Bool, cornerImage: () -> Content) -> some View {
        return VStack {
            ZStack {
                AmityStoryRingElement(componentId: componentId, showRing: showRing, animateRing: animateRing, showErrorRing: showErrorRing)
                    .frame(width: 64, height: 64)
                    .accessibilityIdentifier(AccessibilityID.Story.AmityStoryTabComponent.storyRingView)
                
                AsyncImage(placeholder: AmityIcon.defaultCommunity.getImageResource(), url: avatar)
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .accessibilityIdentifier(AccessibilityID.Story.AmityStoryTabComponent.avatarImageView)
                
                if showErrorRing {
                    Image(AmityIcon.errorStoryIcon.getImageResource())
                        .frame(width: 22.0, height: 22.0)
                        .offset(x: 22, y: 22)
                } else {
                    cornerImage()
                        .accessibilityIdentifier(AccessibilityID.Story.AmityStoryTabComponent.createStoryButton)
                }
            }
            
            HStack(spacing: 0) {
                Image(AmityIcon.lockBlackIcon.getImageResource())
                    .renderingMode(.template)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .scaledToFit()
                    .frame(width: 20, height: 12)
                    .offset(y: -1)
                    .isHidden(hideLockIcon)
                    
                Text(name)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColor)))
                    .frame(height: 20, alignment: .leading)
                    .accessibilityIdentifier(AccessibilityID.Story.AmityStoryTabComponent.targetNameTextView)
            }
        }
    }
}
