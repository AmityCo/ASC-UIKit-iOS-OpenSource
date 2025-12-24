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
    
    @Published var hasCreatePermission = true
    
    // Fetch upcoming events. If initial limit > 0, then only first n events will be loaded in array. If initial limit is <= 0, we treat it as infinite scroll
    func loadEvents(eventStatus: AmityEventStatus, originId: String?, originType: AmityEventOriginType = .community, onlyMyEvents: Bool = false, userId: String? = nil, initialLimit: Int = 0, orderBy: AmityEventOrderOption = .ascending) {
        let queryOptions = AmityEventQueryOptions(originType: originType, originId: originId, status: eventStatus, userId: onlyMyEvents ? AmityUIKit4Manager.client.currentUserId : userId, onlyAttendee: onlyMyEvents ? true : false, orderBy: orderBy)
        
        guard queryState != .loading else { return }
        
        queryState = .loading
        
        collection = manager.getEvents(options: queryOptions)
        token = collection?.observe { [weak self] liveCollection, _, error in
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
                        
            if isFirstPageLoad && initialLimit > 0 {
                self.events = Array(liveCollection.snapshots.prefix(initialLimit))
            } else {
                self.events = liveCollection.snapshots
            }
            
            self.queryState = .loaded
        }
    }
    
    func loadMoreEvents() {
        guard let collection, collection.hasNext else { return }
        
        isFirstPageLoad = false

        queryState = .loading
        collection.nextPage()
    }
    
    func canViewMoreEvents() -> Bool {
        guard let collection, !events.isEmpty else { return false }
        
        return events.count < collection.snapshots.count
    }
    
    func checkEventPermission() {
        let isGuestUser = AmityUIKitManagerInternal.shared.isGuestUser
        guard !isGuestUser else {
            self.hasCreatePermission = false
            return
        }
        
        AmityUIKit4Manager.client.hasPermission(.createEvent) { isAllowed in
            self.hasCreatePermission = isAllowed
        }
    }
}
