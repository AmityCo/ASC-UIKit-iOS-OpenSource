//
//  HappeningNowEventComponent.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 3/11/25.
//

import SwiftUI
import Foundation
import AmitySDK

// Internal component
struct HappeningNowEventComponent: View {
    
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @ObservedObject var viewModel: AmityEventFeedViewModel
    
    var body: some View {
        if viewModel.events.isEmpty && viewModel.queryState == .loading {
            loadingState
        } else {
            eventList
        }
    }
    
    var eventList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AmityLocalizedStringSet.Social.eventListHappeningNowTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
            
            ZStack {
                if viewModel.events.count == 1 {
                    EventCardView(style: .large, event: viewModel.events[0])
                        .onTapGesture {
                            showEventDetailPage(event: viewModel.events[0])
                        }
                } else {
                    ScrollView(.horizontal, showsIndicators: false){
                        LazyHStack(spacing: 12) {
                            ForEach(viewModel.events, id: \.eventId) { event in
                                EventCardView(style: .medium, event: event)
                                    .onTapGesture {
                                        showEventDetailPage(event: event)
                                    }
                            }
                        }
                    }
                }
            }
        }
    }
    
    var loadingState: some View {
        VStack(alignment: .leading, spacing: 22) {
            SkeletonRectangle(height: 12, width: 140)
            
            EventCardSkeletonView(style: .large)
        }
    }
    
    func showEventDetailPage(event: AmityEvent) {
        let eventDetailPage = AmityEventDetailPage(event: event)
        let host = AmitySwiftUIHostingController(rootView: eventDetailPage)
        self.host.controller?.navigationController?.pushViewController(host, animated: true)
    }
}
