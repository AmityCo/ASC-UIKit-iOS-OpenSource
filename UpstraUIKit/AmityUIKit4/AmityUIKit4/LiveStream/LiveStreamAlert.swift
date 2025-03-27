//
//  LiveStreamAlert.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 14/3/25.
//

import SwiftUI

class LiveStreamAlert: ObservableObject {
    typealias AlertAction = (() -> Void)?
    
    static let shared: LiveStreamAlert = LiveStreamAlert()
    
    @Published
    var isPresented: Bool = false
    var alertState: State = .streamError
    
    enum State {
        case streamEndedManually(action: AlertAction)
        case streamEndedDueToMaxDuration(action: AlertAction)
        case streamDiscard(action: AlertAction)
        case streamError
        case thumbnailError(_ isInappropriate: Bool)
        
        var title: String {
            switch self {
            case .streamEndedManually:
                AmityLocalizedStringSet.Social.liveStreamAlertEndLiveTitle.localizedString
            case .streamEndedDueToMaxDuration:
                AmityLocalizedStringSet.Social.liveStreamAlertEndAtMaxDurationTitle.localizedString
            case .streamDiscard:
                AmityLocalizedStringSet.Social.liveStreamAlertDiscardStreamTitle.localizedString
            case .streamError:
                AmityLocalizedStringSet.Social.liveStreamAlertStreamErrorTitle.localizedString
            case .thumbnailError(let isInappropriate):
                isInappropriate ? AmityLocalizedStringSet.Social.liveStreamAlertThumbnailUploadInappropriateErrorTitle.localizedString : AmityLocalizedStringSet.Social.liveStreamAlertThumbnailUploadErrorTitle.localizedString
            }
        }
        
        var message: String {
            switch self {
            case .streamEndedManually:
                AmityLocalizedStringSet.Social.liveStreamAlertEndLiveDesc.localizedString
            case .streamEndedDueToMaxDuration:
                AmityLocalizedStringSet.Social.liveStreamAlertEndAtMaxDurationMessage.localizedString
            case .streamDiscard:
                AmityLocalizedStringSet.Social.liveStreamAlertDiscardStreamMessage.localizedString
            case .streamError:
                AmityLocalizedStringSet.Social.liveStreamAlertStreamErrorMessage.localizedString
            case .thumbnailError(let isInappropriate):
                isInappropriate ? AmityLocalizedStringSet.Social.liveStreamAlertThumbnailUploadInappropriateErrorMessage.localizedString : AmityLocalizedStringSet.Social.liveStreamAlertThumbnailUploadErrorMessage.localizedString
            }
        }
        
        // First button
        var primaryButton: Alert.Button {
            switch self {
            case .streamEndedManually:
                return .cancel()
            case .streamDiscard:
                return .cancel()
            default:
                return .cancel()
                
            }
        }
        
        // Second button
        var secondaryButton: Alert.Button {
            switch self {
            case .streamEndedManually(let action):
                return .destructive(Text(AmityLocalizedStringSet.Social.liveStreamAlertEndButton.localizedString), action: action)
            case .streamDiscard(let action):
                return .destructive(Text(AmityLocalizedStringSet.General.discard.localizedString), action: action)
            default:
                return .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString))
            }
        }
        
        var dismissButton: Alert.Button? {
            switch self {
            case .streamError, .thumbnailError:
                return .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString))
            case .streamEndedDueToMaxDuration(let action):
                return .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString), action: action)
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
        alertState = .streamError
    }
}
