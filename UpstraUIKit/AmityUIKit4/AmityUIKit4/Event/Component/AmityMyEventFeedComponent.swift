//
//  AmityMyEventFeedComponent.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 3/11/25.
//

import SwiftUI
import AmitySDK

public struct AmityMyEventFeedComponent: AmityComponentView {
    
    public var pageId: PageId?
    public var id: ComponentId {
        return .myEventFeedComponent
    }
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    @StateObject var viewConfig: AmityViewConfigController
    @StateObject var upcomingEventFeedViewModel = AmityEventFeedViewModel()
    @StateObject var pastEventFeedViewModel = AmityEventFeedViewModel()
    
    public init(pageId: PageId? = .socialHomePage) {
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .myEventFeedComponent))
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text(AmityLocalizedStringSet.Social.myEventFeedUpcoming.localizedString)
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                    .padding(.top, 16)
                
                UpcomingEventComponent(viewModel: upcomingEventFeedViewModel, supportInfiniteScroll: false)
                
                Button(AmityLocalizedStringSet.Social.exploreEventViewAll.localizedString) {
                    AmityUIKitManagerInternal.shared.behavior.myEventFeedComponentBehavior?.goToUpcomingEventsPage(context: .init(component: self, event: nil))
                }
                .buttonStyle(AmityLineButtonStyle(viewConfig: viewConfig))
                .isHidden(!upcomingEventFeedViewModel.canViewMoreEvents())

                Text(AmityLocalizedStringSet.Social.myEventFeedPast.localizedString)
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                    .padding(.top, 16)
                
                PastEventComponent(viewModel: pastEventFeedViewModel, supportInfiniteScroll: false)
                
                Button(AmityLocalizedStringSet.Social.exploreEventViewAll.localizedString) {
                    AmityUIKitManagerInternal.shared.behavior.myEventFeedComponentBehavior?.goToPastEventsPage(context: .init(component: self, event: nil))
                }
                .buttonStyle(AmityLineButtonStyle(viewConfig: viewConfig))
                .isHidden(!pastEventFeedViewModel.canViewMoreEvents())
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            upcomingEventFeedViewModel.loadEvents(eventStatus: .scheduled, originId: nil, onlyMyEvents: true, initialLimit: 5)
            pastEventFeedViewModel.loadEvents(eventStatus: .ended, originId: nil, onlyMyEvents: true, initialLimit: 5, orderBy: .descending)
        }
    }
}

open class AmityMyEventFeedComponentBehavior {

    open class Context {
        
        let component: AmityMyEventFeedComponent
        let event: AmityEvent?
        
        init(component: AmityMyEventFeedComponent, event: AmityEvent?) {
            self.component = component
            self.event = event
        }
    }
    
    public init() { }
    
    public func goToUpcomingEventsPage(context: AmityMyEventFeedComponentBehavior.Context) {
        let page = AmityUpcomingEventsPage(context: .init(onlyMyEvents: true))
        let hostController = AmitySwiftUIHostingController(rootView: page)
        hostController.navigationController?.isNavigationBarHidden = true
        
        context.component.host.controller?.navigationController?.pushViewController(hostController, animated: true)
    }
    
    public func goToPastEventsPage(context: AmityMyEventFeedComponentBehavior.Context) {
        let page = AmityPastEventsPage()
        let hostController = AmitySwiftUIHostingController(rootView: page)
        hostController.navigationController?.isNavigationBarHidden = true

        context.component.host.controller?.navigationController?.pushViewController(hostController, animated: true)
    }
    
    public func goToEventDetailPage(context: AmityMyEventFeedComponentBehavior.Context) {
        guard let event = context.event else { return }
        let eventDetailPage = AmityEventDetailPage(event: event)
        let host = AmitySwiftUIHostingController(rootView: eventDetailPage)
        context.component.host.controller?.navigationController?.pushViewController(host)
    }
}
