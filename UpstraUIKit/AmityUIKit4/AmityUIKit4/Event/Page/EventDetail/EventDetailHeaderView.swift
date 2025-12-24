//
//  EventDetailHeaderView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 31/10/25.
//

import SwiftUI
import AmitySDK

struct EventDetailHeaderView: View {
    
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    @EnvironmentObject var viewConfig: AmityViewConfigController
    @EnvironmentObject var alertHandler: EventDetailPageAlert
    
    @ObservedObject var viewModel: AmityEventDetailPageViewModel
    let event: AmityEvent
    
    let onAttendeeTap: () -> Void
    let onUserTap: () -> Void
    let onCommunityTap: () -> Void
    
    @State var showAddToCalendarSheet = false
    @State var showJoinAndAddToCalendarSheet = false
    @State var showRSVPOptionSheet = false
        
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(placeholder: AmityIcon.eventImagePlaceholder.imageResource, url: URL(string: event.coverImage?.mediumFileURL ?? ""), contentMode: .fill)
                .frame(height: 188)
            
            VStack(alignment: .leading, spacing: 0) {
                // Community Name Section
                HStack(spacing: 0) {
                    Text(viewModel.eventStatus.statusDescription.uppercased())
                        .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade1)))
                    
                    if let community = event.targetCommunity {
                        Text("•")
                            .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade1)))
                            .padding(.horizontal, 4)
                        
                        if !community.isPublic {
                            Image(AmityIcon.lockBlackIcon.imageResource)
                                .resizable()
                                .frame(width: 16, height: 16)
                                .padding(.horizontal, 2)
                        }
                        
                        Text(community.displayName)
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                            .padding(.leading, 2)
                            .lineLimit(1)
                            .onTapGesture {
                                onCommunityTap()
                            }
                        
                        Image(AmityIcon.verifiedBadge.imageResource)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .padding(.horizontal, 4)
                            .visibleWhen(community.isOfficial)
                    }
                }
                
                // Title
                Text(event.title)
                    .applyTextStyle(.headline(Color(viewConfig.theme.baseColor)))
                    .lineLimit(2)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                
                // Date and Time Section
                HStack(alignment: .center, spacing: 12) {
                    // Date Card
                    VStack(spacing: 0) {
                        let components = Calendar.current.dateComponents([.month, .day], from: event.startTime)
                        let monthIndex = components.month ?? 1
                        let month = Calendar.current.shortMonthSymbols[monthIndex - 1]
                        let day = components.day ?? 1
                        
                        Text(month)
                            .applyTextStyle(.custom(10, .regular, Color(viewConfig.theme.baseColorShade1)))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 2)
                            .background(Color(viewConfig.theme.baseColorShade4))
                            .multilineTextAlignment(.center)
                        
                        Text("\(day)")
                            .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                        
                        Spacer(minLength: 0.5)
                    }
                    .frame(width: 40, height: 40)
                    .border(radius: 8, borderColor: Color(viewConfig.theme.baseColorShade4), borderWidth: 1)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    let eventTime = EventTimestamp(startTime: event.startTime, endTime: event.endTime).formattedTime
                    InfoLabelView(title: AmityLocalizedStringSet.Social.eventDetailHeaderStarts.localizedString, info: eventTime)
                }
                .padding(.bottom, 8)
                
                // Event Type Section
                HStack(alignment: .center, spacing: 12) {
                    
                    // Location Icon Card
                    Image(event.type == .inPerson ? AmityIcon.eventLocationIcon.imageResource : AmityIcon.externalPlatformIcon.imageResource)
                        .frame(width: 20, height: 20)
                        .padding(10)
                        .border(radius: 8, borderColor: Color(viewConfig.theme.baseColorShade4), borderWidth: 1)
                    
                    // Event Type Details
                    InfoLabelView(title: AmityLocalizedStringSet.Social.eventDetailHeaderEventType.localizedString, info: event.type == .inPerson ? AmityLocalizedStringSet.Social.eventDetailHeaderInPerson.localizedString : AmityLocalizedStringSet.Social.eventDetailHeaderVirtual.localizedString)
                }
                .padding(.bottom, 8)
                
                // Attendee
                let attendeeCount = event.rsvpCount
                if attendeeCount > 0 {
                    HStack(alignment: .center, spacing: 12) {
                        Image(AmityIcon.eventAttendeeIcon.imageResource)
                            .frame(width: 20, height: 20)
                            .padding(10)
                            .border(radius: 8, borderColor: Color(viewConfig.theme.baseColorShade4), borderWidth: 1)
                        
                        InfoLabelView(title: AmityLocalizedStringSet.Social.eventDetailHeaderAttendees.localizedString, info: "\(event.rsvpCount.formattedCountString)")
                        
                        Spacer()
                    }
                    .padding(.bottom, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        AmityUserAction.perform(host: host) {
                            onAttendeeTap()
                        }
                    }
                }
                
                // Hosted By Section
                HStack(alignment: .center, spacing: 12) {
                    
                    let avatarUrl = event.creator?.getAvatarInfo()?.fileURL ?? ""
                    AmityUserProfileImageView(displayName: event.creator?.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString, avatarURL: URL(string: avatarUrl))
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    
                    // Host Details
                    VStack(alignment: .leading, spacing: 0) {
                        Text(AmityLocalizedStringSet.Social.eventDetailHeaderHostedBy.localizedString)
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                        
                        HStack(spacing: 4) {
                            Text(event.creator?.displayName ?? AmityLocalizedStringSet.Social.eventDetailHeaderUnknownUser.localizedString)
                                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                            
                            Image(AmityIcon.brandBadge.imageResource)
                                .resizable()
                                .frame(width: 16, height: 16)
                                .visibleWhen(event.creator?.isBrand ?? false)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onUserTap()
                }
                
                rsvpButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 4)
        }
        .bottomSheet(isShowing: $showAddToCalendarSheet, height: .contentSize) {
            VStack(spacing: 0) {
                AmityAddCalendarEventSheetView(action: {
                    viewModel.addEventToCalendar(event: event) { isSuccess in
                        Toast.showToast(style: isSuccess ? .success : .warning, message: isSuccess ? AmityLocalizedStringSet.Social.eventDetailHeaderEventAddedToCalendar.localizedString : AmityLocalizedStringSet.Social.eventDetailHeaderNoCalendarAccess.localizedString)
                    }
                    
                    showAddToCalendarSheet = false
                })
                .padding(.bottom, 32)
            }
        }
        .bottomSheet(isShowing: $showJoinAndAddToCalendarSheet, height: .contentSize) {
            VStack(spacing: 0) {
                let isJoinApprovalRequired = viewModel.community?.requiresJoinApproval ?? false

                AmityJoinCommunitySheetView(community: viewModel.community, user: AmityUIKit4Manager.client.user?.snapshot, canRSVPEvent: !isJoinApprovalRequired, joinAction: {
                    joinCommunityAndRSVP()
                }, cancelAction: {
                    showJoinAndAddToCalendarSheet = false
                })
                .padding(.bottom, 32)
            }
        }
        .bottomSheet(isShowing: $showRSVPOptionSheet, height: .contentSize) {
            rsvpOptionSheet
                .padding(.bottom, 64)
        }
    }
    
    @ViewBuilder
    var rsvpButton: some View {
        switch viewModel.rsvpButtonState {
        case .going, .notGoing:
            Button {
                showRSVPOptionSheet = true
            } label: {
                buttonContent
            }
            .buttonStyle(AmityLineButtonStyle(viewConfig: viewConfig))
            .padding(.top, 16)
            .disabled(viewModel.eventStatus == .live || viewModel.eventStatus == .ended)
        case .unanswered:
            let isMember = viewModel.community?.isJoined ?? false
            Button {
                // 1. For guest user, we prevent action & show toast. This is handled through this generic user action
                AmityUserAction.perform(host: host) {

                    // 2. Handle event started scenario
                    guard canChangeEventStatusNow() else {
                        Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.eventDetailHeaderAttendingStatusChangeNotAllowed.localizedString)

                        viewModel.hideRsvpButton()
                        viewModel.updateEventStatus(status: .live)

                        return
                    }
                    
                    // 3. If user has joined the community, rsvp immediately and show sheet to add to calendar.
                    if isMember {
                        Task { @MainActor in
                            // RSVP event first
                            let isSuccess = await rsvpCurrentEvent(status: .going, isUpdate: false)
                            
                            // Show add to calendar popup
                            if isSuccess {
                                self.showAddToCalendarSheet = true
                            }
                        }
                    } else {
                        showJoinAndAddToCalendarSheet = true
                    }
                }
            } label: {
                buttonContent
            }
            .buttonStyle(AmityPrimaryButtonStyle(viewConfig: viewConfig))
            .padding(.top, 16)
            .isHidden(viewModel.event?.status == .ended || viewModel.event?.status == .live ? true : false)
        case .none:
            EmptyView()
        }
    }
    
    var buttonContent: some View {
        HStack {
            Image(viewModel.rsvpButtonState.icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            
            Text(viewModel.rsvpButtonState.title)
        }
    }
    
    struct InfoLabelView: View {
        @EnvironmentObject var viewConfig: AmityViewConfigController
        
        let title: String
        let info: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                
                Text(info)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                    .lineLimit(1)
            }
        }
    }
    
    func joinCommunityAndRSVP() {
        // let isJoinApprovalRequired = viewModel.community?.requiresJoinApproval ?? false
        let hasPendingJoinRequest = (self.viewModel.communityJoinRequest?.status ?? .none) == .pending
        
        if hasPendingJoinRequest {
            // Dismiss this sheet
            showJoinAndAddToCalendarSheet = false
            
            // Show join request approval alert
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                alertHandler.show(for: .pendingJoinRequest)
            }
            
            return
        }
        
        Task { @MainActor in
            do {
                let joinResult = try await viewModel.community?.join()
                
                switch joinResult {
                case .pending(_):
                    // Dismiss this sheet
                    showJoinAndAddToCalendarSheet = false
                    
                    // Show join request approval alert
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        alertHandler.show(for: .pendingJoinRequest)
                    }
                case .success:
                    // RSVP Event
                    let _ = await rsvpCurrentEvent(status: .going, isUpdate: false)
                    
                    // Dismiss this sheet
                    showJoinAndAddToCalendarSheet = false
                    
                    // Show add to calendar sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showAddToCalendarSheet = true
                    }
                default:
                    break
                }
                
            } catch {
                Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.eventDetailHeaderJoinCommunityFailed.localizedString)
            }
        }
    }
    
    func rsvpCurrentEvent(status: AmityEventResponseStatus, isUpdate: Bool) async -> Bool {
        Log.add("RSVPing current event as \(status.rawValue)")
        switch status {
        case .going:
            do {
                if isUpdate {
                    try await viewModel.updateRSVP(status: .going)
                } else {
                    try await viewModel.rsvpEventAsGoing()
                }
                
                return true
            } catch {
                Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.eventDetailHeaderUpdateAttendingStatusFailed.localizedString)
            }
        case .notGoing:
            do {
                // RSVP as going first
                try await viewModel.updateRSVP(status: .notGoing)

                return true
            } catch {
                Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.eventDetailHeaderUpdateAttendingStatusFailed.localizedString)
            }
        default:
            break
        }
        
        return false
    }
    
    func canChangeEventStatusNow() -> Bool {
        // 2. Handle event started scenario
        if Date() > event.startTime {
            return false
        }
        
        return true
    }
    
}

extension AmityEvent {
    
    var isLive: Bool {
        return status == .live
    }
    
    var isEnded: Bool {
        return status == .ended
    }
    
    // Note:
    // Once we switch to room based api, check for livestream object instead.
    var isLiveStreamEvent: Bool {
        let eventUrl = self.externalUrl ?? ""
        return self.type == .virtual && eventUrl.isEmpty
    }
}

extension AmityEventStatus {
    
    var statusDescription: String {
        switch self {
        case .live:
            return AmityLocalizedStringSet.Social.eventDetailHeaderStatusHappeningNow.localizedString
        case .scheduled:
            return AmityLocalizedStringSet.Social.eventDetailHeaderStatusUpcoming.localizedString
        case .cancelled:
            return AmityLocalizedStringSet.Social.eventDetailHeaderStatusCancelled.localizedString
        case .ended:
            return AmityLocalizedStringSet.Social.eventDetailHeaderStatusEnded.localizedString
        @unknown default:
            return ""
        }
    }
}
