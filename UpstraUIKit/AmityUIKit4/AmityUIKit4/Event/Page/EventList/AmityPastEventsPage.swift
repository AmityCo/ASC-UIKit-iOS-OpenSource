//
//  AmityPastEventsPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 3/11/25.
//

import SwiftUI

public struct AmityPastEventsPage: AmityPageView {
    
    public var id: PageId {
        return .pastEventsPage
    }
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController = .init(pageId: .pastEventsPage)
    
    @State private var tabIndex: Int = 0
    @State private var tabs: [String] = [AmityLocalizedStringSet.Social.eventListTabAll.localizedString, AmityLocalizedStringSet.Social.eventListTabHosting.localizedString]
    @State private var scrollViewHeight: CGSize = .zero
    
    @StateObject var allEventFeed = AmityEventFeedViewModel()
    @StateObject var hostingEventFeed = AmityEventFeedViewModel()
    
    public init() { }
    
    public var body: some View {
        VStack(spacing: 0) {
            AmityNavigationBar(title: AmityLocalizedStringSet.Social.eventListPastEventsTitle.localizedString, showBackButton: true)
            
            if allEventFeed.hasCreatePermission {
                VStack(spacing: 0) {
                    TabBarView(currentTab: $tabIndex, tabBarOptions: $tabs)
                        .selectedTabColor(viewConfig.theme.highlightColor)
                        .onChange(of: tabIndex) { value in
                            
                        }
                        .padding(.leading, 16)
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 1)
                }
                .padding(.top, 16)
            }
            
            TabView(selection: $tabIndex) {
                allEventList
                    .tag(0)
                
                hostingEventList
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .padding(.top, 8)
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
        .onAppear {
            allEventFeed.checkEventPermission()
        }
        .onChange(of: allEventFeed.hasCreatePermission) { hasPermission in
            if hasPermission {
                tabs = [AmityLocalizedStringSet.Social.eventListTabAll.localizedString, AmityLocalizedStringSet.Social.eventListTabHosting.localizedString]
            } else {
                tabs = [AmityLocalizedStringSet.Social.eventListTabAll.localizedString]
            }
        }
    }
    
    var allEventList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            PastEventComponent(viewModel: allEventFeed)
                .onAppear {
                    allEventFeed.loadEvents(eventStatus: .ended, originId: nil, onlyMyEvents: true, orderBy: .descending)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .frame(minHeight: allEventFeed.events.isEmpty && allEventFeed.queryState == .loaded ?  scrollViewHeight.height : nil)
        }
        .readSize { size in
            scrollViewHeight = size
        }
    }
    
    var hostingEventList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            HostingEventComponent(viewModel: hostingEventFeed)
                .onAppear {
                    hostingEventFeed.loadEvents(eventStatus: .ended, originId: nil, orderBy: .descending)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .frame(minHeight: hostingEventFeed.events.isEmpty && hostingEventFeed.queryState == .loaded ?  scrollViewHeight.height : nil)
        }
    }
}
