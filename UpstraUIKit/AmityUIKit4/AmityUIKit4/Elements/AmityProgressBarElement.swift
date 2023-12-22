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
        .progressBarElementId
    }
    
    @ObservedObject var progressBarViewModel: AmityProgressBarElementViewModel
    
    var body: some View {
        AmityView(configType: .element(configId), 
                  config: { configDict in
            
        }) { config in
            
            Capsule()
                .fill(.gray.opacity(0.5))
                .overlay (
                    Capsule()
                        .fill(.white)
                        .frame(width: progressBarViewModel.progress)
                    
                    ,alignment: .leading
                )
        }
    }
    
}

class AmityProgressBarElementViewModel: ObservableObject {
    @Published var progress: CGFloat = 0.0
}
