//
//  ReactionListHeader.swift
//  AmityUIKit4
//
//  Created by Nishan on 16/5/2567 BE.
//

import SwiftUI

struct ReactionListHeader: View {
    
    @Binding var currentTab: Int
    @Binding var tabBarItems: [ReactionTabItem]
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ReactionTabBarView(currentTab: $currentTab, tabBarOptions: $tabBarItems)
                .frame(height: 30)
                .zIndex(1)
                .accessibilityIdentifier(AccessibilityID.Chat.ReactionList.reactionListTab)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                .offset(y: -1)
        }
    }
}
