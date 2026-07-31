//
//  ChatReactionListHeader.swift
//  AmityUIKit4
//
//  Design-system clone of ReactionListHeader / ReactionTabBarView for the Chat
//  (.message) reaction list. Figma [UIKit 4.0] Chat (xt0KYneEXrCO37HBIFgYT9) 10848:54968.
//  Reuses the shared ReactionTabItem model.
//

import SwiftUI

struct ChatReactionListHeader: View {

    @Binding var currentTab: Int
    @Binding var tabBarItems: [ReactionTabItem]
    @EnvironmentObject private var viewConfig: AmityViewConfigController

    var body: some View {
        ZStack(alignment: .bottom) {
            ChatReactionTabBarView(currentTab: $currentTab, tabBarOptions: $tabBarItems)
                .frame(height: 30)
                .zIndex(1)
                .accessibilityIdentifier(AccessibilityID.Chat.ReactionList.reactionListTab)

            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(viewConfig.color(.lineDividerPostDefault)))
                .offset(y: -1)
        }
    }
}

struct ChatReactionTabBarView: View {
    @Binding var currentTab: Int
    @Namespace var namespace
    @Binding var tabBarOptions: [ReactionTabItem]

    init(currentTab: Binding<Int>, tabBarOptions: Binding<[ReactionTabItem]>) {
        self._currentTab = currentTab
        self._tabBarOptions = tabBarOptions
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(tabBarOptions) { item in
                    ChatReactionTabBarItemView(currentTab: $currentTab, namespace: namespace.self, tabItem: item)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ChatReactionTabBarItemView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController

    @Binding var currentTab: Int
    let namespace: Namespace.ID
    var tabItem: ReactionTabItem

    private var tabTextColor: Color {
        Color(viewConfig.color(currentTab == tabItem.index ? .textTabUnderlinedActive : .textTabUnderlinedDefault))
    }

    var body: some View {
        Button {
            self.currentTab = tabItem.index
        } label: {
            VStack(spacing: 7) {

                HStack {
                    if let imageResource = tabItem.image {
                        Image(imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    } else {
                        Text(AmityStringProvider.common.resolveReactionDisplayName(tabItem.name))
                            .applyTextStyle(.titleBold(tabTextColor))
                    }

                    Text("\(tabItem.count.formattedCountString)")
                        .applyTextStyle(.titleBold(tabTextColor))
                }

                // Underline
                if currentTab == tabItem.index {
                    Color(viewConfig.color(.lineTabUnderlinedActive))
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
