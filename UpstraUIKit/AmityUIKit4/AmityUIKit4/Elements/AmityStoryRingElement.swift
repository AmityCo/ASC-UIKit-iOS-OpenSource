//
//  AmityStoryRingElement.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/27/23.
//

import SwiftUI

struct AmityStoryRingElement: AmityElementView {
    
    var pageId: PageId?
    
    var componentId: ComponentId?
    
    var id: ElementId {
        return .storyRingElementId
    }
    
    var animateRing: Bool
    
    var body: some View {
        AmityView(configType: .element(configId),
                  config: { configDict -> (progressColor: [Color], backgroundColor: Color) in
            
            let progressColor = (configDict["progress_color"] as? [String] ?? ["#339AF9", "#78FA58"]).map({ hex in
                Color(UIColor(hex: hex))
            })
            let backgroundColor = Color(UIColor(hex: configDict["background_color"] as? String ?? "#EBECEF"))
            
            return (progressColor, backgroundColor)
            
        }) { config in
            
            Circle()
                .stroke(lineWidth: 3.0)
                .fill(
                    LinearGradient(colors: animateRing
                                   ? config.progressColor : [config.backgroundColor]
                                   , startPoint: .top, endPoint: .bottom)
                )
        }
    }
    
}
