//
//  EventDetailPage+BottomSheet.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 17/11/25.
//

import SwiftUI

extension AmityEventDetailPage {
    
    var createPostOptionSheet: some View {
        VStack(spacing: 0) {
            BottomSheetItemView(icon: AmityIcon.createPostMenuIcon.imageResource, text: AmityLocalizedStringSet.Social.createPostBottomSheetTitle.localizedString)
                .onTapGesture {
                    showCreateBottomSheet.toggle()
                    host.controller?.dismiss(animated: false)
                    
                    guard let event = viewModel.event else { return }
                    
                    AmityUIKitManagerInternal.shared.behavior.eventDetailPageBehavior?.goToPostComposerPage(context: .init(page: self, event: event))
                }
                .isHidden(viewConfig.isHidden(elementId: .createPostButton))
            
            BottomSheetItemView(icon: AmityIcon.createPollMenuIcon.imageResource, text: AmityLocalizedStringSet.Social.pollLabel.localizedString, iconSize: CGSize(width: 20, height: 20))
                .onTapGesture {
                    showCreateBottomSheet.toggle()
                    host.controller?.dismiss(animated: false)
                    
                    showPollSelectionView.toggle()
                }
                .isHidden(viewConfig.isHidden(elementId: .createPollButton))
            
            BottomSheetItemView(icon: AmityIcon.createLivestreamMenuIcon.imageResource, text: AmityLocalizedStringSet.Social.liveStreamLabel.localizedString, iconSize: CGSize(width: 20, height: 20))
                .onTapGesture {
                    showCreateBottomSheet.toggle()
                    host.controller?.dismiss(animated: false)
                    
                    guard let event = viewModel.event else { return }
                    
                    AmityUIKitManagerInternal.shared.behavior.eventDetailPageBehavior?.goToDiscussionLivestreamComposerPage(context: .init(page: self, event: event))
                }
                .isHidden(viewConfig.isHidden(elementId: .createLivestreamButton))
        }
        .padding(.bottom, 32)
    }
    
    var pollTypeSelectionSheet: some View {
        PollTypeSelectionView(onNextAction: { pollType in
            
            showPollSelectionView = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard let event = viewModel.event else { return }
                
                AmityUIKitManagerInternal.shared.behavior.eventDetailPageBehavior?.goToPollPostComposerPage(context: .init(page: self, event: event), pollType: pollType)
            }
            
        })
        .background(Color(viewConfig.theme.backgroundColor))
        .environmentObject(viewConfig)
    }
    
    var eventCreatedSuccessSheet: some View {
        VStack(spacing: 16) {
            Image(AmityIcon.DesignSystem.calendarStarL.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                .padding(.vertical, 10)
              

            VStack(spacing: 8) {
                Text(AmityLocalizedStringSet.Social.eventPostCreatedSuccessTitle.localizedString)
                    .applyTextStyle(.headline(Color(viewConfig.theme.baseColor)))
                    .multilineTextAlignment(.center)
                
                Text(AmityLocalizedStringSet.Social.eventPostCreatedSuccessDescription.localizedString)
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade1)))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)

            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)

            VStack(spacing: 12) {
                
                Button(AmityLocalizedStringSet.Social.eventPostCreatedSuccessPrimary.localizedString) {
                    showEventCreatedSuccessSheet = false
                    host.controller?.dismiss(animated: false)

                    guard let event = viewModel.event else { return }
                    AmityUIKit4Manager.behaviour.eventDetailPageBehavior?.goToEventPostToFeed(context: .init(page: self, event: event))
                }
                .buttonStyle(AmityPrimaryButtonStyle(viewConfig: viewConfig, size: .expanded))

                Button(AmityLocalizedStringSet.Social.eventPostCreatedSuccessSecondary.localizedString) {
                    showEventCreatedSuccessSheet = false
                }
                .buttonStyle(AmityLineButtonStyle(viewConfig: viewConfig, size: .expanded))
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 32)
    }

    var menuOptionSheet: some View {
        VStack(spacing: 0) {
            
            if viewModel.isEventHost || viewModel.hasUpdatePermission {
                BottomSheetItemView(icon: AmityIcon.editCommentIcon.imageResource, text: AmityLocalizedStringSet.Social.eventDetailPageEditEvent.localizedString)
                    .onTapGesture {
                        // Dismiss
                        showMenuBottomSheet.toggle()
                        
                        guard let event = viewModel.event else { return }
                        
                        let currentTime = Date()
                        let eventEditThresholdTime = Calendar.current.date(byAdding: .minute, value: -15, to: event.startTime) ?? currentTime // we allow editing event < 15 minutes before start time
                        if currentTime > eventEditThresholdTime {
                            Log.warn("Event has already started! Cannot edit this event")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                alertHandler.show(for: .editErrorDueToTimeLimit)
                            }
                            return
                        }
                        
                        AmityUIKit4Manager.behaviour.eventDetailPageBehavior?.goToEventSetupPage(context: .init(page: self, event: event))
                    }
                    .accessibilityIdentifier(AccessibilityID.Event.EventDetailPage.editButton)
            }

            // "Post event to feed" — create an event post referencing this event.
            // Visible to host / moderator / member of the event's community.
            let canPostEventToFeed = viewModel.isEventHost || (viewModel.event?.targetCommunity?.isJoined ?? false)
            if canPostEventToFeed {
                BottomSheetItemView(icon: AmityIcon.editPostEvent.imageResource, text: AmityLocalizedStringSet.Social.eventDetailPagePostEventToFeed.localizedString)
                    .onTapGesture {
                        showMenuBottomSheet.toggle()
                        // Dismiss the menu sheet synchronously before presenting the flow —
                        // otherwise the host is "already presenting" it (same pattern as the
                        // "Create post" item above).
                        host.controller?.dismiss(animated: false)

                        guard let event = viewModel.event else { return }

                        AmityUIKit4Manager.behaviour.eventDetailPageBehavior?.goToEventPostToFeed(context: .init(page: self, event: event))
                    }
            }

            let isEventEnded = viewModel.event?.status == .ended
            let canAddToCalendar = !isEventEnded && (viewModel.isEventHost || viewModel.rsvpButtonState == .going)

            // Only for upcoming & happening event
            if canAddToCalendar {
                BottomSheetItemView(icon: AmityIcon.addToCalendarButtonIcon.imageResource, text: AmityLocalizedStringSet.Social.eventDetailHeaderAddToCalendar.localizedString)
                    .onTapGesture {
                        guard let event = viewModel.event else { return }

                        viewModel.addEventToCalendar(event: event) { isSuccess in
                            Toast.showToast(style: isSuccess ? .success : .warning, message: isSuccess ? AmityLocalizedStringSet.Social.eventDetailHeaderEventAddedToCalendar.localizedString : AmityLocalizedStringSet.Social.eventDetailHeaderNoCalendarAccess.localizedString)
                        }
                    }
            }

            if viewModel.canShareEventLink {
                let copyLinkConfig = viewConfig.forElement(.copyLink)
                let shareLinkConfig = viewConfig.forElement(.shareLink)

                BottomSheetItemView(icon: AmityIcon.copyLinkIcon.imageResource, text: copyLinkConfig.text ?? AmityLocalizedStringSet.Social.eventDetailCopyEventLink.localizedString)
                    .onTapGesture {
                        showMenuBottomSheet.toggle()

                        guard let link = viewModel.generateEventShareableLink() else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.eventDetailFailedToCopyLink.localizedString)
                            }
                            return
                        }

                        UIPasteboard.general.string = link

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.eventInfoLinkCopied.localizedString)
                        }
                    }

                BottomSheetItemView(icon: AmityIcon.shareToIcon.imageResource, text: shareLinkConfig.text ?? AmityLocalizedStringSet.Social.socialShareTo.localizedString)
                    .onTapGesture {
                        showMenuBottomSheet.toggle()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            showShareActivitySheet.toggle()
                        }
                    }
            }

            if viewModel.isEventHost || viewModel.hasDeletePermission {
                BottomSheetItemView(icon: AmityIcon.trashBinIcon.imageResource, text: AmityLocalizedStringSet.Social.eventDetailPageDeleteEvent.localizedString, isDestructive: true)
                    .onTapGesture {
                        // Dismiss
                        showMenuBottomSheet.toggle()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            alertHandler.show(for: .deleteConfirmation(action: {
                                Task { @MainActor in
                                    do {
                                        try await viewModel.deleteEvent()
                                        
                                        Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.eventDetailPageEventDeleted.localizedString)
                                        
                                        let isNewlyCreatedEvent = context?.isNewEvent ?? false
                                        if isNewlyCreatedEvent {
                                            host.controller?.navigationController?.dismiss(animated: true)
                                        } else {
                                            self.host.controller?.navigationController?.popViewController(animated: true)
                                        }
                                    } catch {
                                        Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.eventDetailPageDeleteFailed.localizedString)
                                    }
                                }
                            }))
                        }
                    }
                    .accessibilityIdentifier(AccessibilityID.Event.EventDetailPage.deleteButton)
            }
        }
        .padding(.bottom, 32)
    }

    func shouldShowEventMenuOption() -> Bool {
        // Host can edit, delete, add to calendar, share
        if viewModel.isEventHost { return true }

        // Moderator can delete
        if viewModel.hasDeletePermission { return true }

        // UPDATE_EVENT holder can edit
        if viewModel.hasUpdatePermission { return true }

        // Members (and hosts) can post the event to a feed — must match the
        let canPostEventToFeed = viewModel.isEventHost || (viewModel.event?.targetCommunity?.isJoined ?? false)
        if canPostEventToFeed { return true }

        // Any user (member / non-member / visitor) can copy or share when sharing is enabled
        if viewModel.canShareEventLink { return true }

        // Attending members can still add the event to their calendar
        let isEventEnded = viewModel.event?.status == .ended
        let isAttendingEvent = viewModel.rsvpButtonState == .going
        return !isEventEnded && isAttendingEvent
    }
}

extension EventDetailHeaderView {
    
    var rsvpOptionSheet: some View {
        VStack(spacing: 0) {
            BottomSheetRadioItemView(isSelected: viewModel.rsvpButtonState == .going, text: AmityLocalizedStringSet.Social.eventDetailHeaderGoing.localizedString)
                .onTapGesture {
                    // Dismiss sheet
                    showRSVPOptionSheet = false

                    // Changing from
                    // - Going - Going: Do nothing
                    // - Not Going - Going: Add to event sheet
                    if viewModel.rsvpButtonState == .notGoing {
                        guard canChangeEventStatusNow() else {
                            Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.eventDetailHeaderAttendingStatusChangeNotAllowed.localizedString)

                            viewModel.updateEventStatus(status: .live)

                            return
                        }

                        Task { @MainActor in
                            let isSuccess = await rsvpCurrentEvent(status: .going, isUpdate: true)

                            if isSuccess {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    showAddToCalendarSheet = true
                                }
                            }
                        }
                    }
                }

            BottomSheetRadioItemView(isSelected: viewModel.rsvpButtonState == .notGoing, text: AmityLocalizedStringSet.Social.eventDetailHeaderNotGoing.localizedString)
                .onTapGesture {
                    showRSVPOptionSheet = false

                    // Changing from
                    // - Not Going -> Not Going: Do nothing
                    // - Going -> Not Going: Success Toast
                    if viewModel.rsvpButtonState == .going {

                        guard canChangeEventStatusNow() else {
                            Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.eventDetailHeaderAttendingStatusChangeNotAllowed.localizedString)

                            viewModel.updateEventStatus(status: .live)

                            return
                        }

                        Task { @MainActor in
                            let isSuccess = await rsvpCurrentEvent(status: .notGoing, isUpdate: true)
                            if isSuccess {
                                Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.eventDetailHeaderUpdateAttendingStatusSuccess.localizedString)
                            }
                        }
                    }
                }
        }
    }
}
