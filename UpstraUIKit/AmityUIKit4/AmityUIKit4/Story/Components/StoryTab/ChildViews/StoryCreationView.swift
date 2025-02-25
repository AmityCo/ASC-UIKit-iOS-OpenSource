//
//  StoryCreationView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/21/23.
//

import SwiftUI

struct StoryCreationView: View {
    let componentId: ComponentId
    @ObservedObject var viewModel: StoryCreationViewModel
    
    var body: some View {
        VStack {
            ZStack {
                AmityStoryRingElement(componentId: componentId, showRing: viewModel.animateRing, animateRing: false, showErrorRing: false)
                    .frame(width: 64, height: 64)
                
                Image(uiImage: viewModel.avartar ?? UIImage())
                    .resizable()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                
                AmityCreateNewStoryButtonElement(componentId: componentId)
                    .frame(width: 22.0, height: 22.0)
                    .offset(x: 22, y: 22)
            }
            
            Text(viewModel.name)
                .font(AmityTextStyle.caption(.clear).getFont())
                .frame(height: 20, alignment: .leading)
        }
    }
    
}

class StoryCreationViewModel: ObservableObject, Identifiable {
    var id: String {
        UUID().uuidString
    }
    
    @Published var avartar: UIImage?
    @Published var name: String
    @Published var animateRing: Bool
    
    init(avartar: UIImage?, name: String, animateRing: Bool) {
        self.avartar = avartar
        self.name = name
        self.animateRing = animateRing
    }
}
