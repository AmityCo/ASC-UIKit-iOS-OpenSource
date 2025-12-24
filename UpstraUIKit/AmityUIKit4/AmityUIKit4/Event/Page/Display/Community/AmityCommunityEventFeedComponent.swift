//
//  AmityCommunityEventFeedComponent.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 3/11/25.
//

import SwiftUI
import AmitySDK

public struct AmityCommunityEventFeedComponent: View {
    
    enum EventTab: String, Identifiable {
        case upcoming
        case past
        
        var id: String {
            return self.rawValue
        }
    }
    
    @StateObject var liveFeedViewModel = AmityEventFeedViewModel()
    @StateObject var upcomingFeedViewModel = AmityEventFeedViewModel()
    @StateObject var pastFeedViewModel = AmityEventFeedViewModel()

    @State private var currentTab: EventTab = .upcoming

    let communityId: String
    
    public init(communityId: String) {
        self.communityId = communityId
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            eventFeed
                .visibleWhen(liveFeedViewModel.emptyFeedState != .private)
            
            PrivateCommunityFeedView()
                .visibleWhen(liveFeedViewModel.emptyFeedState == .private)
        }
    }
    
    var eventFeed: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !liveFeedViewModel.events.isEmpty {
                HappeningNowEventComponent(viewModel: liveFeedViewModel)
                    .padding(.top, 16)
            }
            
            HStack {
                ChipTabButton(title: AmityLocalizedStringSet.Social.communityEventFeedUpcoming.localizedString, selected: currentTab == .upcoming) {
                    currentTab = .upcoming
                }

                ChipTabButton(title: AmityLocalizedStringSet.Social.communityEventFeedPast.localizedString, selected: currentTab == .past) {
                    currentTab = .past
                }
            }
            .padding(.top, 16)
            
            switch currentTab {
            case .upcoming:
                UpcomingEventComponent(viewModel: upcomingFeedViewModel)
                    .onAppear {
                        upcomingFeedViewModel.loadEvents(eventStatus: .scheduled, originId: communityId)
                    }
            case .past:
                PastEventComponent(viewModel: pastFeedViewModel)
                    .onAppear {
                        pastFeedViewModel.loadEvents(eventStatus: .ended, originId: communityId, orderBy: .descending)
                    }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
        .onAppear {
            liveFeedViewModel.loadEvents(eventStatus: .live, originId: communityId)
        }
    }
    
    var happeningNowEmptyState: some View {
        VStack(alignment: .leading, spacing: 22) {
            SkeletonRectangle(height: 12, width: 140)
            
            EventCardSkeletonView(style: .large)
        }
    }
    
    var eventListEmptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            EventCardSkeletonView(style: .list)
            EventCardSkeletonView(style: .list)
            EventCardSkeletonView(style: .list)
        }
    }
}
