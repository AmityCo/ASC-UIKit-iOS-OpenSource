//
//  HostingEventComponent.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 4/11/25.
//

import SwiftUI
import AmitySDK

// Internal component
struct HostingEventComponent: View {
    
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    @EnvironmentObject var viewConfig: AmityViewConfigController
    @ObservedObject var viewModel: AmityEventFeedViewModel
    
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
                        if let lastEvent = viewModel.events.last, lastEvent.eventId == event.eventId {
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
