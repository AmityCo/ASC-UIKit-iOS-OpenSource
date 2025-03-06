//
//  AmityMessageAudioController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 2/12/2563 BE.
//  Copyright © 2563 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

// Manage audio message
final class AmityMessageAudioController {
    
    private let subChannelId: String
    private weak var repository: AmityMessageRepository?
    
    private var token: AmityNotificationToken?
    private var message: AmityObject<AmityMessage>?
    
    init(subChannelId: String, repository: AmityMessageRepository?) {
        self.subChannelId = subChannelId
        self.repository = repository
    }
    
    func create(completion: @escaping () -> Void) {
        
        guard let audioURL = AmityAudioRecorder.shared.getAudioFileURL() else {
            Log.add("Audio file not found")
            return
        }
        
        guard let repository = repository else {
            return
        }
        
        let createOptions = AmityAudioMessageCreateOptions(subChannelId: subChannelId, attachment: .localURL(url: audioURL), fileName: AmityAudioRecorder.shared.fileName)
        Task { @MainActor in
            do {
                // This message returned is already synced with the server.
                let message = try await repository.createAudioMessage(options: createOptions)
                
                AmityAudioRecorder.shared.updateFilename(withFilename: message.messageId)
                
                completion()
            } catch let error {
                Log.warn("Error while creating audio message")
            }
        }
    }
    
}
