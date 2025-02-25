//
//  AmityCreateNewStoryButtonElement.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/28/23.
//

import SwiftUI

struct AmityCreateNewStoryButtonElement: AmityElementView {
    var pageId: PageId?
    
    var componentId: ComponentId?
    
    var id: ElementId {
        return .createNewStoryButtonElement
    }
    
    init(pageId: PageId? = nil, componentId: ComponentId? = nil) {
        self.pageId = pageId
        self.componentId = componentId
    }
    
    
    var body: some View {
        AmityView(configId: configId,
                  config: { configDict -> (backgroundColor: Color, createStoryIcon: ImageResource) in
            
            let backgroundColor = Color(UIColor(hex: configDict["background_color"] as? String ?? "#000000"))
            
            let createStoryIcon = AmityIcon.getImageResource(named: configDict["create_new_story_icon"] as? String ?? "createStoryIcon")
            
            return (backgroundColor, createStoryIcon)
            
        }) { config in
            
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(config.backgroundColor)
                    
                    Image(config.createStoryIcon)
                        .resizable()
                        .frame(width: geometry.size.width - 3, height: geometry.size.height - 3)
                }
            }
        }
    }
}
