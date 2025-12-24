//
//  EventDetailPageAlert.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 10/11/25.
//

import SwiftUI

class EventDetailPageAlert: ObservableObject {
    typealias AlertAction = (() -> Void)?
    
    @Published
    var isPresented: Bool = false
    var alertState: State = .editErrorDueToTimeLimit
    
    enum State {
        case editErrorDueToTimeLimit
        case editDiscardConfirmation(action: AlertAction)
        case deleteConfirmation(action: AlertAction)
        case pendingJoinRequest
        
        var title: String {
            switch self {
            case .editErrorDueToTimeLimit:
                AmityLocalizedStringSet.Social.eventDetailAlertEditNotPossibleTitle.localizedString
            case .editDiscardConfirmation:
                AmityLocalizedStringSet.Social.eventDetailAlertLeaveWithoutFinishingTitle.localizedString
            case .deleteConfirmation:
                AmityLocalizedStringSet.Social.eventDetailAlertDeleteEventTitle.localizedString
            case .pendingJoinRequest:
                "You’ll be able to RSVP once your join request is accepted"
            }
        }
        
        var message: String {
            switch self {
            case .editErrorDueToTimeLimit:
                AmityLocalizedStringSet.Social.eventDetailAlertEditNotPossibleMessage.localizedString
            case .editDiscardConfirmation:
                AmityLocalizedStringSet.Social.eventDetailAlertLeaveWithoutFinishingMessage.localizedString
            case .deleteConfirmation:
                AmityLocalizedStringSet.Social.eventDetailAlertDeleteEventMessage.localizedString
            case .pendingJoinRequest:
                "Requested to join the community. You'll be notified once your request is accepted."
            }
        }
        
        // First button
        var primaryButton: Alert.Button {
            switch self {
            case .editErrorDueToTimeLimit:
                return .cancel()
            case .deleteConfirmation:
                return .cancel()
            default:
                return .cancel()
            }
        }
        
        // Second button
        var secondaryButton: Alert.Button {
            switch self {
            case .editDiscardConfirmation(let action):
                return .destructive(Text(AmityLocalizedStringSet.General.leave.localizedString), action: action)
            case .deleteConfirmation(let action):
                return .destructive(Text(AmityLocalizedStringSet.General.delete.localizedString), action: action)
            default:
                return .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString))
            }
        }
        
        var dismissButton: Alert.Button? {
            switch self {
            case .editErrorDueToTimeLimit, .pendingJoinRequest:
                return    .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString))
            default:
                return nil
            }
        }
    }
    
    func show(for state: State) {
        self.alertState = state
        self.isPresented = true
    }
    
    func hide() {
        isPresented = false
        alertState = .editErrorDueToTimeLimit
    }
    
}
