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
                "Maximum file size limit reached"
            case .unsupportedVideoType:
                "Unsupported video type"
            case .maxClipDuration:
                "Clip must be under 15 minutes"
            case .clipTooShort:
                "Clip too short"
            case .discardClip:
                "Discard this clip?"
            case .failedToUpload:
                "Failed to upload"
            }
        }
        
        var message: String {
            switch self {
            case .maxFileSize:
                "Please choose a video with smaller file size."
            case .unsupportedVideoType:
                "Please choose a different video to upload."
            case .maxClipDuration:
                "Please choose a different video to upload."
            case .clipTooShort:
                "Clip must be at least 1 second long."
            case .discardClip:
                "The clip will be permanently discarded. It cannot be undone."
            case .failedToUpload:
                "Please check your connection or choose a different video to upload"
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
                return .default(Text("Keep editing"))
            default:
                return .cancel()
                
            }
        }
        
        // Second button
        var secondaryButton: Alert.Button {
            switch self {
            case .discardClip(let action):
                return .destructive(Text(AmityLocalizedStringSet.General.discard.localizedString), action: action)
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
