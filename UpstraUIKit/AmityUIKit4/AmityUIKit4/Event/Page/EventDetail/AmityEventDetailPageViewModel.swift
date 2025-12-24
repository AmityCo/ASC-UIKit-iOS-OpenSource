//
//  AmityEventDetailPageViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 7/11/25.
//

import Foundation
import AmitySDK

class AmityEventDetailPageViewModel: ObservableObject {
    
    private let eventManager = EventManager()
    private let feedManager = FeedManager()
    private let calendarManager = EventCalendarManager()
    private let eventId: String
    
    @Published var event: AmityEvent?
    @Published var posts: [AmityPost] = []
    @Published var loadingStatus: AmityLoadingStatus = .notLoading
    @Published var isEventUnavailable = false
    @Published var isLoadingEvent = false
    
    // RSVP button state
    @Published var rsvpButtonState: EventRSVPButtonState = .none
    @Published var eventStatus: AmityEventStatus = .scheduled
    
    @Published var isEventHost: Bool = false
    @Published var hasCreatePermission = false
    @Published var hasUpdatePermission = false
    @Published var hasDeletePermission = false
    
    var eventToken: AmityNotificationToken?
    var feedToken: AmityNotificationToken?
    var feedCollection: AmityCollection<AmityPost>?
    var eventResponse: AmityEventResponse?
    var community: AmityCommunity?
    var communityJoinRequest: AmityJoinRequest?
    
    init(event: AmityEvent) {
        self.event = event
        self.eventStatus = event.status
        self.eventId = event.eventId
        self.setupEventObserver()
        self.fetchMyEventResponse()
        self.setupEventPermission()
    }
    
    init(eventId: String) {
        self.eventId = eventId
        self.event = eventManager.getEvent(eventId: eventId).snapshot
        self.eventStatus = event?.status ?? .scheduled
        self.setupEventObserver()
        self.fetchMyEventResponse()
    }
    
    func setupEventObserver() {
        isLoadingEvent = true
        eventToken = eventManager.getEvent(eventId: eventId).observe({ [weak self] liveObject, error in
            guard let self else { return }
            
            if let _ = error {
                self.isEventUnavailable = true
                self.loadingStatus = .error
                return
            }
            
            guard let snapshot = liveObject.snapshot else { return }
            
            self.event = snapshot
            self.eventStatus = snapshot.status
            self.isLoadingEvent = false
            
            if snapshot.isDeleted {
                self.isEventUnavailable = true
            }
            
            setupCommunity()
            setupEventPermission()
        })
    }
    
    func setupCommunity() {
        guard let event, community == nil else { return }
        
        self.community = event.targetCommunity
        
        Task { @MainActor in
            self.communityJoinRequest = try await self.community?.getMyJoinRequest()
        }
    }
    
    deinit {
        eventToken?.invalidate()
        eventToken = nil
    }
    
    func loadDiscussionFeed() {
        guard let event else { return }
        
        loadingStatus = .loading
        
        // For event based on livestream, a livestream post is auto-created. So we skip this post from discussion feed.
        let skippedPostId = event.postId ?? ""
        feedCollection = feedManager.getCommunityFeedPosts(communityId: event.discussionCommunityId)
        feedToken = feedCollection?.observe({ [weak self] liveCollection, _, error in
            guard let self else { return }
            
            if let _ = error {
                self.loadingStatus = .error
                return
            }
            
            let snapshots = liveCollection.snapshots
            var postList = [AmityPost]()
            snapshots.forEach { post in
                if post.postId != skippedPostId {
                    postList.append(post)
                }
            }
            
            self.posts = postList
            
            self.loadingStatus = .loaded
        })
    }
    
    func loadMoreFeedItems() {
        guard let feedCollection, feedCollection.hasNext else { return }
        
        loadingStatus = .loading
        
        feedCollection.nextPage()
    }
    
    func deleteEvent() async throws {
        guard let event else { return }
        try await eventManager.deleteEvent(eventId: event.eventId)
    }
    
    func setupEventPermission() {
        isEventHost = event?.creator?.userId == AmityUIKit4Manager.client.currentUserId
        
        AmityUIKit4Manager.client.hasPermission(.createEvent) { hasPermission in
            self.hasCreatePermission = hasPermission
        }
        
        AmityUIKit4Manager.client.hasPermission(.updateEvent) { hasPermission in
            self.hasUpdatePermission = hasPermission
        }
        
        AmityUIKit4Manager.client.hasPermission(.deleteEvent) { hasPermission in
            self.hasDeletePermission = hasPermission
        }
    }
    
    // MARK: RSVP
    func fetchMyEventResponse() {
        let eventHostId = event?.creator?.userId ?? ""
        let currentUserId = AmityUIKit4Manager.client.currentUserId ?? ""
        
        guard let event, eventHostId != currentUserId else { return }
        
        Task { @MainActor in
            do {
                let response = try await event.getMyRSVP()
                self.eventResponse = response
                self.rsvpButtonState = EventRSVPButtonState.from(response.status)
            } catch let error {
                self.rsvpButtonState = .unanswered
                Log.warn("Event response error: \(error)")
            }
        }
    }
    
    @MainActor
    func rsvpEventAsGoing() async throws {
        guard let event else { return }
        
        let _ = try await event.createRSVP(status: .going)
        self.rsvpButtonState = .going
    }
    
    @MainActor
    func updateRSVP(status: AmityEventResponseStatus) async throws {
        guard let event else { return }
        
        let _ = try await event.updateRSVP(status: status)
        self.rsvpButtonState = status == .going ? .going : .notGoing
    }
    
    func hideRsvpButton() {
        self.rsvpButtonState = .none
    }
    
    func updateEventStatus(status: AmityEventStatus) {
        self.eventStatus = status
    }
    
    func canSetupLiveStream() -> Bool {
        // Check event status
        guard let event, !event.isEnded else { return false }
        
        // Check stream status
        guard let room = event.room, room.status == .idle else { return false }
        
        // Check host status
        guard let creatorId = room.creatorId, creatorId == AmityUIKit4Manager.client.currentUserId else { return false }
        
        // If event has started
        if event.isLive {
            // Livestream hasn't started yet so we still allow user to setup livestream
            return true
        }
        
        // Else we only allow user to setup livestream before 15 minutes
        let currentTime = Date()
        let startTime = event.startTime
        let before15Minutes = Calendar.current.date(byAdding: .minute, value: -15, to: startTime) ?? currentTime
        
        if currentTime > before15Minutes {
            return true
        }
        
        return false
    }
    
    func addEventToCalendar(event: AmityEvent, onCompletion: @escaping (_ isSuccess: Bool) -> Void) {
        let manager = calendarManager
        manager.requestPermission { isPermissionGranted in
            guard isPermissionGranted else {
                DispatchQueue.main.async {
                    onCompletion(false)
                }
                return
            }
            
            manager.addEvent(event: event)
            
            DispatchQueue.main.async {
                onCompletion(true)
            }
        }
    }
}

enum EventRSVPButtonState: String {
    case going
    case notGoing
    case unanswered
    case none
    
    var title: String {
        switch self {
        case .unanswered:
            return "RSVP"
        case .going:
            return "Going"
        case .notGoing:
            return "Not going"
        case .none:
            return ""
        }
    }
    
    var icon: ImageResource {
        switch self {
        case .going:
            AmityIcon.checkMarkIcon.imageResource
        case .notGoing:
            AmityIcon.closeIcon.imageResource
        case .unanswered:
            AmityIcon.eventRSVPBellIcon.imageResource
        case .none:
            AmityIcon.eventRSVPBellIcon.imageResource
        }
    }
    
    static func from(_ state: AmityEventResponseStatus) -> EventRSVPButtonState {
        switch state {
        case .going:
            return .going
        case .notGoing:
            return .notGoing
        default:
            return .unanswered
        }
    }
}

fileprivate extension AmityRoom {
    
    var isLive: Bool {
        return status == .live || status == .waitingReconnect
    }
    
    var isEnded: Bool {
        return status == .ended || status == .terminated || status == .recorded
    }
}
