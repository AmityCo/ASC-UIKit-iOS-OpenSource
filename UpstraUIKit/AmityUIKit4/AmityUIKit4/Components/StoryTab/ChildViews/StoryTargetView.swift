//
//  StoryTargetView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/21/23.
//

import SwiftUI

struct StoryTargetView<Content: View>: View {
    
    let componentId: ComponentId
    @ViewBuilder let cornerImage: () -> Content
    @ObservedObject var storyTarget: StoryTarget
    
    init(componentId: ComponentId, storyTarget: StoryTarget, @ViewBuilder cornerImage: @escaping () -> Content) {
        self.componentId = componentId
        self.storyTarget = storyTarget
        self.cornerImage = cornerImage
    }
    
    var body: some View {
        getStoryView(avatar: storyTarget.placeholderImage, name: storyTarget.targetName, animateRing: storyTarget.hasUnseen, cornerImage: cornerImage)
    }
    
    private func getStoryView(avatar: UIImage?, name: String, animateRing: Bool, cornerImage: () -> Content) -> some View {
        return VStack {
            ZStack {
                AmityStoryRingElement(componentId: componentId, animateRing: animateRing)
                    .frame(width: 64, height: 64)
                
                Image(uiImage: avatar ?? UIImage())
                    .resizable()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                
                cornerImage()
                
            }
            
            Text(name)
                .font(.system(size: 13))
                .frame(height: 20, alignment: .leading)
        }
    }
}
