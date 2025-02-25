//
//  TabItemView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/19/24.
//
import SwiftUI

struct TabItemView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @Binding var currentTab: Int
    let namespace: Namespace.ID
    var tabItem: TabItem
    
    var body: some View {
        Button {
            self.currentTab = tabItem.index
        } label: {
            VStack(spacing: 0) {
                
                HStack {
                    Image(tabItem.image)
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(currentTab == tabItem.index ? Color(viewConfig.theme.baseColor) : Color(viewConfig.theme.baseColorShade3))
                }
                .padding(.bottom, 12)
                
                // Underline
                if currentTab == tabItem.index {
                    Color(viewConfig.theme.highlightColor)
                        .frame(height: 2)
                        .matchedGeometryEffect(id: "underline",
                                               in: namespace,
                                               properties: .frame)
                } else {
                    Color.clear.frame(height: 2)
                }
            }
            .animation(.easeInOut(duration: 0.1), value: self.currentTab)
        }
        .buttonStyle(.plain)
    }
}


struct TabItem: Identifiable, Equatable {
    let id: UUID
    let index: Int
    let image: ImageResource
    
    init(index: Int, image: ImageResource) {
        self.id = UUID()
        self.index = index
        self.image = image
    }
    
}
