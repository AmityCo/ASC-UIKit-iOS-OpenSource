//
//  StoryTargetView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/21/23.
//

import SwiftUI

struct StoryTargetView<Content: View>: View {
    
    let componentId: ComponentId
    @ViewBuilder private let cornerImage: () -> Content
    @ObservedObject private var storyTarget: StoryTarget
    private let storyTargetName: String
    
    init(componentId: ComponentId, storyTarget: StoryTarget, storyTargetName: String? = nil, @ViewBuilder cornerImage: @escaping () -> Content) {
        self.componentId = componentId
        self.storyTarget = storyTarget
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
    
    private func getStoryView(avatar: UIImage?, name: String, showRing: Bool, animateRing: Bool, showErrorRing: Bool, cornerImage: () -> Content) -> some View {
        return VStack {
            ZStack {
                AmityStoryRingElement(componentId: componentId, showRing: showRing, animateRing: animateRing, showErrorRing: showErrorRing)
                    .frame(width: 64, height: 64)
                
                Image(uiImage: avatar ?? UIImage())
                    .resizable()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                
                if showErrorRing {
                    Image(AmityIcon.errorStoryIcon.getImageResource())
                        .frame(width: 22.0, height: 22.0)
                        .offset(x: 22, y: 22)
                } else {
                    cornerImage()
                }
            }
            
            Text(name)
                .font(.system(size: 13))
                .frame(height: 20, alignment: .leading)
        }
    }
}
