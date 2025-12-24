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
            
            BottomSheetItemView(icon: AmityIcon.createPollMenuIcon.imageResource, text: AmityLocalizedStringSet.Social.pollLabel.localizedString, iconSize: CGSize(width: 20, height: 20))
                .onTapGesture {
                    showCreateBottomSheet.toggle()
                    host.controller?.dismiss(animated: false)
                    
                    showPollSelectionView.toggle()
                }
            
            BottomSheetItemView(icon: AmityIcon.createLivestreamMenuIcon.imageResource, text: AmityLocalizedStringSet.Social.liveStreamLabel.localizedString, iconSize: CGSize(width: 20, height: 20))
                .onTapGesture {
                    showCreateBottomSheet.toggle()
                    host.controller?.dismiss(animated: false)
                    
                    guard let event = viewModel.event else { return }
                    
                    AmityUIKitManagerInternal.shared.behavior.eventDetailPageBehavior?.goToLivestreamPostComposerPage(context: .init(page: self, event: event))
                }
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
        .environmentObject(viewConfig)
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
            
            if viewModel.hasDeletePermission {
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
            }
        }
        .padding(.bottom, 32)
    }
    
    func shouldShowEventMenuOption() -> Bool {
        // For Host or permission holder (moderator)
        let isHostOrModerator = viewModel.isEventHost || viewModel.hasCreatePermission || viewModel.hasUpdatePermission || viewModel.hasDeletePermission
        if isHostOrModerator { return true }
        
        // For Member
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
