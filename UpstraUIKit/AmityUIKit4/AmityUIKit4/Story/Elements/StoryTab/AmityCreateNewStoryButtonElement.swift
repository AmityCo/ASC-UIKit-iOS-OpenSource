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
                  config: { configDict -> ImageResource in
            AmityIcon.getImageResource(named: configDict["create_new_story_icon"] as? String ?? "createStoryIcon")
        }) { createStoryIcon in

            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(Color(AmityUIKitConfigController.shared.getTheme().backgroundColor))

                    Image(createStoryIcon)
                        .resizable()
                        .frame(width: geometry.size.width - 3, height: geometry.size.height - 3)
                }
            }
        }
    }
}
