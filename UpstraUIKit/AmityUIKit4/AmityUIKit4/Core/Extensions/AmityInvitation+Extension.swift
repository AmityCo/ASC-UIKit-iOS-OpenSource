//
//  AmityInvitation+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/25/25.
//

import Foundation
import AmitySDK

extension AmityInvitation {
    func markAsSeen() {
        AmityInvitationSeenManager.shared.markAsSeen(self.invitationId)
    }
    
    func isSeen() -> Bool {
        AmityInvitationSeenManager.shared.isSeen(self.invitationId)
    }
}

// This is temporary solution to manage seen invitations.
// It saves seen invitation IDs to a file in the app's document directory.
// Need to remove this when SDK provides it part of the notification tray service.
fileprivate class AmityInvitationSeenManager {
    static let shared = AmityInvitationSeenManager()
    
    private let fileName = "seen_invitations.json"
    private var fileURL: URL? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentDirectory.appendingPathComponent(fileName)
    }
    
    private(set) var seenInvitationIds: Set<String> = []
    
    private init() {
        loadSeenInvitations()
    }
    
    func markAsSeen(_ invitationId: String) {
        seenInvitationIds.insert(invitationId)
        saveSeenInvitations()
    }
    
    func isSeen(_ invitationId: String) -> Bool {
        seenInvitationIds.contains(invitationId)
    }
    
    private func loadSeenInvitations() {
        guard let fileURL = fileURL else { return }
        
        do {
            // Check if file exists before attempting to load
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                let idsArray = try JSONDecoder().decode([String].self, from: data)
                seenInvitationIds = Set(idsArray)
            }
        } catch {
            // If loading fails, start with empty set
            seenInvitationIds = []
        }
    }
    
    private func saveSeenInvitations() {
        guard let fileURL = fileURL else { return }
        
        do {
            // Convert Set to Array for JSON encoding
            let idsArray = Array(seenInvitationIds)
            let data = try JSONEncoder().encode(idsArray)
            try data.write(to: fileURL)
        } catch {}
    }
}

