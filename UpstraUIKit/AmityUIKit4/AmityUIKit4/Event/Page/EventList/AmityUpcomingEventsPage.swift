//
//  AmityUpcomingEventsPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 3/11/25.
//

import SwiftUI
import AmitySDK
import Foundation

// From ‘Explore’: all events user has permission to see | From ‘My events’: only events that user marked as interested OR hosting
public struct AmityUpcomingEventsPage: AmityPageView {
    
    public var id: PageId {
        return .upcomingEventsPage
    }
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController = .init(pageId: .upcomingEventsPage)
    
    @State private var tabIndex: Int = 0
    @State private var tabs: [String] = [AmityLocalizedStringSet.Social.eventListTabAll.localizedString, AmityLocalizedStringSet.Social.eventListTabHosting.localizedString]
    
    // The upcoming event list view are shared across multiple pages/components.
    // In some cases, we need to show empty state at the center of the page so we compute the height of this scrollview.
    @State private var scrollViewHeight: CGSize = .zero
    
    @StateObject var allEventFeed = AmityEventFeedViewModel()
    @StateObject var hostingEventFeed = AmityEventFeedViewModel()

    var context: AmityUpcomingEventsPage.Context?
    
    public init(context: AmityUpcomingEventsPage.Context? = nil) {
        self.context = context
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            AmityNavigationBar(title: AmityLocalizedStringSet.Social.eventListUpcomingEventsTitle.localizedString, showBackButton: true)
            
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
            UpcomingEventComponent(viewModel: allEventFeed)
                .onAppear {
                    let onlyMyEvents = context?.onlyMyEvents ?? false
                    allEventFeed.loadEvents(eventStatus: .scheduled, originId: nil, onlyMyEvents: onlyMyEvents)
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
                    hostingEventFeed.loadEvents(eventStatus: .scheduled, originId: nil, userId: AmityUIKit4Manager.client.currentUserId)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .frame(minHeight: hostingEventFeed.events.isEmpty && hostingEventFeed.queryState == .loaded ?  scrollViewHeight.height : nil)
        }
    }
    
    func showEventDetailPage(event: AmityEvent) {
        let eventDetailPage = AmityEventDetailPage(event: event)
        let host = AmitySwiftUIHostingController(rootView: eventDetailPage)
        self.host.controller?.navigationController?.pushViewController(host)
    }
}

extension AmityUpcomingEventsPage {
    
    public struct Context {
        let onlyMyEvents: Bool
        
        public init(onlyMyEvents: Bool = false) {
            self.onlyMyEvents = onlyMyEvents
        }
    }
}
