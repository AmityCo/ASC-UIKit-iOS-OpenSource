//
//  EventManager.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 16/10/25.
//

import SwiftUI
import AmitySDK

class EventManager {
    private let eventRepo = AmityEventRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func createEvent(options: AmityEventCreateOptions) async throws -> AmityEvent {
        return try await eventRepo.createEvent(options: options)
    }
    
    func updateEvent(eventId: String, options: AmityEventUpdateOptions) async throws -> AmityEvent {
        return try await eventRepo.updateEvent(id: eventId, options: options)
    }
    
    func deleteEvent(eventId: String) async throws {
        return try await eventRepo.deleteEvent(id: eventId)
    }
    
    func getEvent(eventId: String) -> AmityObject<AmityEvent> {
        return eventRepo.getEvent(id: eventId)
    }
    
    func getEvents(options: AmityEventQueryOptions) -> AmityCollection<AmityEvent> {
        return eventRepo.getEvents(options: options)
    }
}
