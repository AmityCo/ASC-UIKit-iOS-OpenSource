//
//  PastEventComponent.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 3/11/25.
//

import SwiftUI
import Foundation
import AmitySDK

// Internal component
struct PastEventComponent: View {
    
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    @EnvironmentObject var viewConfig: AmityViewConfigController
    @ObservedObject var viewModel: AmityEventFeedViewModel
    
    let supportInfiniteScroll: Bool
    
    init(viewModel: AmityEventFeedViewModel, supportInfiniteScroll: Bool = true) {
        self.viewModel = viewModel
        self.supportInfiniteScroll = supportInfiniteScroll
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            if viewModel.events.isEmpty && viewModel.queryState == .loading {
                EventComponentLoadingState()
            } else if viewModel.events.isEmpty && viewModel.queryState == .loaded {
                EventComponentEmptyState()
                    .padding(.vertical, 40)
            } else {
                eventList
            }
        }
    }
    
    var eventList: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.events, id: \.eventId) { event in
                EventCardView(style: .list, event: event)
                    .onTapGesture {
                        showEventDetailPage(event: event)
                    }
                    .onAppear {
                        if let lastEvent = viewModel.events.last, lastEvent.eventId == event.eventId, supportInfiniteScroll {
                            viewModel.loadMoreEvents()
                        }
                    }
            }
        }
    }
    
    func showEventDetailPage(event: AmityEvent) {
        let eventDetailPage = AmityEventDetailPage(event: event)
        let host = AmitySwiftUIHostingController(rootView: eventDetailPage)
        self.host.controller?.navigationController?.pushViewController(host)
    }
}
