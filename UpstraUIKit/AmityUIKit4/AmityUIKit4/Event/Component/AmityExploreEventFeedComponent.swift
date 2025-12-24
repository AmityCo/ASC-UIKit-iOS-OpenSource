//
//  AmityExploreEventFeedComponent.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 3/11/25.
//

import SwiftUI
import AmitySDK

public struct AmityExploreEventFeedComponent: AmityComponentView {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject var viewConfig: AmityViewConfigController
    
    @StateObject var liveEventFeed = AmityEventFeedViewModel()
    @StateObject var upcomingEventFeed = AmityEventFeedViewModel()
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        return .exploreEventFeedComponent
    }
    
    public init(pageId: PageId? = .socialHomePage) {
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .exploreEventFeedComponent))
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if !liveEventFeed.events.isEmpty {
                    HappeningNowEventComponent(viewModel: liveEventFeed)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }
                
                Text(AmityLocalizedStringSet.Social.exploreEventRecommendedForYou.localizedString)
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                UpcomingEventComponent(viewModel: upcomingEventFeed, supportInfiniteScroll: false)
                    .padding(.top, upcomingEventFeed.events.isEmpty && upcomingEventFeed.queryState == .loaded ? 40 : 16)
                
                Button(AmityLocalizedStringSet.Social.exploreEventViewAll.localizedString) {
                    AmityUIKitManagerInternal.shared.behavior.exploreEventFeedComponentBehavior?.goToUpcomingEventsPage(context: .init(component: self, event: nil))
                }
                .buttonStyle(AmityLineButtonStyle(viewConfig: viewConfig))
                .opacity(upcomingEventFeed.canViewMoreEvents() ? 1 : 0)
                .disabled(!upcomingEventFeed.canViewMoreEvents())
                .padding(.vertical, 16)
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            liveEventFeed.loadEvents(eventStatus: .live, originId: nil)
            upcomingEventFeed.loadEvents(eventStatus: .scheduled, originId: nil, initialLimit: 5)
        }
    }
}

open class AmityExploreEventFeedComponentBehavior {

    open class Context {
        
        let component: AmityExploreEventFeedComponent
        let event: AmityEvent?
        
        init(component: AmityExploreEventFeedComponent, event: AmityEvent?) {
            self.component = component
            self.event = event
        }
    }
    
    public init() { }
    
    public func goToUpcomingEventsPage(context: AmityExploreEventFeedComponentBehavior.Context) {
        let page = AmityUpcomingEventsPage(context: .init(onlyMyEvents: false))
        let hostController = AmitySwiftUIHostingController(rootView: page)
        
        context.component.host.controller?.navigationController?.pushViewController(hostController, animated: true)
    }
    
    public func goToEventDetailPage(context: AmityExploreEventFeedComponentBehavior.Context) {
        guard let event = context.event else { return }
        let eventDetailPage = AmityEventDetailPage(event: event)
        let host = AmitySwiftUIHostingController(rootView: eventDetailPage)
        context.component.host.controller?.navigationController?.pushViewController(host)
    }
}
