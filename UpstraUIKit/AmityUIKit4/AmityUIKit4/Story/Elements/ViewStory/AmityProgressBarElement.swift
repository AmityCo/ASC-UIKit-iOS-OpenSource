//
//  AmityProgressBarElement.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/29/23.
//

import SwiftUI

struct AmityProgressBarElement: AmityElementView {
    
    var pageId: PageId?
    
    var componentId: ComponentId?
    
    var id: ElementId {
        .progressBarElement
    }
    
    @ObservedObject var progressBarViewModel: AmityProgressBarElementViewModel
    
    var body: some View {
        AmityView(configId: configId, 
                  config: { configDict -> (progressColor: Color, backgroundColor: Color) in
            let progressColor = Color(UIColor(hex: configDict["progress_color"] as? String ?? "#FFFFFF"))
            let backgroundColor = Color(UIColor(hex: configDict["background_color"] as? String ?? "#FFFFFF"))
            
            return (progressColor, backgroundColor)
        }) { config in
            
            Capsule()
                .fill(config.backgroundColor.opacity(0.4))
                .overlay (
                    Capsule()
                        .fill(config.progressColor)
                        .frame(width: progressBarViewModel.progress)
                    
                    ,alignment: .leading
                )
        }
    }
    
}

class AmityProgressBarElementViewModel: ObservableObject {
    @Published var progress: CGFloat = 0.0
}
