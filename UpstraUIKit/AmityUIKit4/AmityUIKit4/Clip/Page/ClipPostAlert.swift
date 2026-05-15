//
//  ClipPostAlert.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 16/6/25.
//

import SwiftUI

class ClipPostAlert: ObservableObject {    
    @Published
    var isPresented: Bool = false
    var alertState: State = .maxFileSize
    
    enum State {
        case maxFileSize
        case unsupportedVideoType
        case maxClipDuration
        case clipTooShort
        case discardClip(action: DefaultTapAction?)
        case failedToUpload(action: DefaultTapAction?)
        
        var title: String {
            switch self {
            case .maxFileSize:
                AmityLocalizedStringSet.Social.clipAlertMaxFileSizeTitle.localizedString
            case .unsupportedVideoType:
                AmityLocalizedStringSet.Social.clipAlertUnsupportedVideoTitle.localizedString
            case .maxClipDuration:
                AmityLocalizedStringSet.Social.clipAlertMaxDurationTitle.localizedString
            case .clipTooShort:
                AmityLocalizedStringSet.Social.clipAlertTooShortTitle.localizedString
            case .discardClip:
                AmityLocalizedStringSet.Social.clipAlertDiscardTitle.localizedString
            case .failedToUpload:
                AmityLocalizedStringSet.Social.clipAlertFailedUploadTitle.localizedString
            }
        }
        
        var message: String {
            switch self {
            case .maxFileSize:
                AmityLocalizedStringSet.Social.clipAlertMaxFileSizeMessage.localizedString
            case .unsupportedVideoType:
                AmityLocalizedStringSet.Social.clipAlertUnsupportedVideoMessage.localizedString
            case .maxClipDuration:
                AmityLocalizedStringSet.Social.clipAlertUnsupportedVideoMessage.localizedString
            case .clipTooShort:
                AmityLocalizedStringSet.Social.clipAlertTooShortMessage.localizedString
            case .discardClip:
                AmityLocalizedStringSet.Social.clipAlertDiscardMessage.localizedString
            case .failedToUpload:
                AmityLocalizedStringSet.Social.clipAlertFailedUploadMessage.localizedString
            }
        }
        
        var dismissButton: Alert.Button? {
            switch self {
            case .maxFileSize, .unsupportedVideoType, .maxClipDuration, .clipTooShort:
                return .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString))
            case .failedToUpload(let action):
                return .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString), action: action)
            case .discardClip:
                return nil
            }
        }
        
        // First button
        var primaryButton: Alert.Button {
            switch self {
            case .discardClip:
                return .default(Text(AmityLocalizedStringSet.Social.keepEditing.localizedString))
            default:
                return .cancel()
                
            }
        }
        
        // Second button
        var secondaryButton: Alert.Button {
            switch self {
            case .discardClip(let action):
                return .destructive(Text(AmityLocalizedStringSet.Social.discard.localizedString), action: action)
            default:
                return .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString))
            }
        }
    }
    
    func show(for state: State) {
        self.alertState = state
        self.isPresented = true
    }
    
    func hide() {
        isPresented = false
        alertState = .maxFileSize
    }
}
