//
//  AmityEventAttendeesPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 14/11/25.
//

import Foundation
import AmitySDK

public struct AmityEventAttendeesPage: AmityPageView {

    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    @StateObject var viewModel: AmityEventAttendeesPageViewModel

    public var id: PageId {
        return .eventAttendeesPage
    }
    
    init(eventId: String) {
        self._viewModel = StateObject(wrappedValue: AmityEventAttendeesPageViewModel(eventId: eventId))
    }
    
    init(event: AmityEvent) {
        self._viewModel = StateObject(wrappedValue: AmityEventAttendeesPageViewModel(event: event))
    }
    
    @StateObject var viewConfig = AmityViewConfigController(pageId: .eventAttendeesPage)
    
    public var body: some View {
        VStack(spacing: 0) {
            AmityNavigationBar(title: AmityLocalizedStringSet.Social.eventAttendeesPageTitle.localizedString, showBackButton: true)

            ScrollView(.vertical, showsIndicators: false) {
                if viewModel.rsvpUsers.isEmpty && viewModel.rsvpQueryState == .loading {
                    loadingState
                } else {
                    attendeeList
                }
            }
            .padding(.horizontal, 16)
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
        .onAppear {
            viewModel.loadAttendees()
        }
    }
    
    var loadingState: some View {
        ForEach(0..<3, id: \.self) { _ in
            UserCellSkeletonView()
                .padding(.horizontal, 16)
        }
    }
    
    var attendeeList: some View {
        LazyVStack(alignment: .leading) {
            ForEach(viewModel.rsvpUsers, id: \.userId) { user in
                HStack(spacing: 12) {
                    let displayName = user.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString
                    
                    ZStack(alignment: .bottomTrailing) {
                        AmityUserProfileImageView(displayName: displayName, avatarURL: URL(string: user.getAvatarInfo()?.fileURL ?? ""))
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        
                        if user.hasModeratorRole {
                            Color(viewConfig.theme.primaryColor.blend(.shade3))
                                .frame(width: 18, height: 18)
                                .clipShape(Circle())
                                .overlay(
                                    Image(AmityIcon.moderatorBadgeIcon.getImageResource())
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 16, height: 16)
                                )
                        }
                    }
                    
                    UserDisplayNameLabel(name: displayName, isBrand: user.isBrand)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    openUserProfile(userId: user.userId)
                }
            }
        }
    }
    
    func openUserProfile(userId: String) {
        let userProfilePage = AmityUserProfilePage(userId: userId)
        let controller = AmitySwiftUIHostingController(rootView: userProfilePage)
        host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
}

class AmityEventAttendeesPageViewModel: ObservableObject {
    
    let eventId: String
    var event: AmityEvent?
    
    private let manager = EventManager()
    private var eventToken: AmityNotificationToken?
    private var rsvpToken: AmityNotificationToken?
    private var rsvpCollection: AmityCollection<AmityEventResponse>?
    
    @Published var rsvpUsers = [AmityUser]()
    @Published var rsvpQueryState: QueryState = .idle
    
    init(eventId: String) {
        self.eventId = eventId
        self.fetchEvent(eventId: eventId)
    }
    
    init(event: AmityEvent) {
        self.event = event
        self.eventId = event.eventId
    }
    
    func fetchEvent(eventId: String) {
        eventToken = manager.getEvent(eventId: eventId).observe({ [weak self] liveObject, error in
            guard let self, let liveEvent = liveObject.snapshot else { return }
            
            self.event = liveEvent
            self.eventToken?.invalidate()
            self.eventToken = nil
            
            // Load attendees
            self.loadAttendees()
        })
    }
    
    func loadAttendees() {
        guard let event else { return }
        
        rsvpQueryState = .loading
        rsvpCollection = event.getRSVPs(status: .going)
        rsvpToken = rsvpCollection?.observe({ [weak self] liveCollection, _, error in
            guard let self else { return }
            
            if let error {
                rsvpQueryState = .error
                rsvpToken?.invalidate()
                rsvpToken = nil
                rsvpCollection = nil
                return
            }
            
            var users = [AmityUser]()
            let snapshots = liveCollection.snapshots
            snapshots.forEach { response in
                if let user = response.user {
                    users.append(user)
                }
            }
            
            rsvpUsers = users
            rsvpQueryState = .loaded
        })
    }
    
    func loadMore() {
        guard let rsvpCollection, rsvpCollection.hasNext else { return }
        
        rsvpQueryState = .loading
        rsvpCollection.nextPage()
    }
}
