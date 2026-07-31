//
//  AmityEventFeedViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 3/11/25.
//

import SwiftUI
import AmitySDK

class AmityEventFeedViewModel: ObservableObject {
    
    @Published var events: [AmityEvent] = []
    @Published var queryState: QueryState = .idle
    var error: Error?
    var emptyFeedState: EmptyUserFeedViewState = .empty
    
    private let manager = EventManager()
    private var collection: AmityCollection<AmityEvent>?
    private var token: AmityNotificationToken?
    private var isFirstPageLoad = true
    
    // PDT-4178 — the SDK query has no `excludeOwnEvents` option yet, so drop the logged in
    // user's own events from the snapshots. Off by default; only Explore opts in.
    private var excludeOwnEvents = false
    
    @Published var hasCreatePermission = true
    
    // Fetch upcoming events. If initial limit > 0, then only first n events will be loaded in array. If initial limit is <= 0, we treat it as infinite scroll
    func loadEvents(eventStatus: AmityEventStatus, originId: String?, originType: AmityEventOriginType = .community, onlyMyEvents: Bool = false, userId: String? = nil, initialLimit: Int = 0, orderBy: AmityEventOrderOption = .ascending, excludeOwnEvents: Bool = false) {
        let queryOptions = AmityEventQueryOptions(originType: originType, originId: originId, status: eventStatus, userId: onlyMyEvents ? AmityUIKit4Manager.client.currentUserId : userId, onlyAttendee: onlyMyEvents ? true : false, orderBy: orderBy)
        
        guard queryState != .loading else { return }
        
        self.excludeOwnEvents = excludeOwnEvents
        queryState = .loading
        
        collection = manager.getEvents(options: queryOptions)
        token = collection?.observe { [weak self] liveCollection, error in
            guard let self else { return }
            
            if let error {
                self.error = error
                
                if error.isAmityErrorCode(.visitorPermissionDenied) || error.isAmityErrorCode(.permissionDenied) || error.isAmityErrorCode(.forbiddenError) {
                    self.emptyFeedState = .private
                }
                
                self.queryState = .error
                self.token?.invalidate()
                self.token = nil
                self.collection = nil
                return
            }
                        
            let visibleEvents = self.excludingOwnEvents(liveCollection.snapshots)

            if isFirstPageLoad && initialLimit > 0 {
                self.events = Array(visibleEvents.prefix(initialLimit))
            } else {
                self.events = visibleEvents
            }
            
            self.queryState = .loaded
        }
    }

    /// Removes events created by the logged in user. No-op unless the caller passed
    /// `excludeOwnEvents: true`, so every other event feed is unaffected.
    private func excludingOwnEvents(_ events: [AmityEvent]) -> [AmityEvent] {
        guard excludeOwnEvents, let currentUserId = AmityUIKit4Manager.client.currentUserId else { return events }
        return events.filter { $0.userId != currentUserId }
    }
    
    func loadMoreEvents() {
        guard let collection, collection.hasNext else { return }
        
        isFirstPageLoad = false

        queryState = .loading
        collection.nextPage()
    }
    
    func canViewMoreEvents() -> Bool {
        guard let collection, !events.isEmpty else { return false }

        // Compare like with like: both sides exclude own events when the caller opted in,
        // so "View all" reflects whether more of *this* feed's events remain rather than
        // being kept alive by own events that were filtered out of `events`.
        return events.count < excludingOwnEvents(collection.snapshots).count
    }
    
    func checkEventPermission() {
        let isGuestUser = AmityUIKitManagerInternal.shared.isGuestUser
        guard !isGuestUser else {
            self.hasCreatePermission = false
            return
        }
        
        Task { @MainActor in
            self.hasCreatePermission = await AmityUIKit4Manager.client.hasPermission(.createEvent)
        }
    }
}
