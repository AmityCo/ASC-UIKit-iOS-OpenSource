//
//  AmityEventSetupPageViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 15/10/25.
//

import AmitySDK
import Foundation
import UIKit

class AmityEventSetupPageViewModel: ObservableObject {
    
    let fileRepostiory: AmityFileRepository = AmityFileRepository(client: AmityUIKitManagerInternal.shared.client)
    let eventManager = EventManager()
    
    let event: AmityEvent?
    
    init(event: AmityEvent?) {
        self.event = event
    }
    
    func createEvent(draft: EventDraft, targetId: String) async throws -> AmityEvent {
        
        var imageData: AmityImageData?
        if let avatar = draft.avatar {
            imageData = try await fileRepostiory.uploadImage(avatar, progress: nil)
        }
        
        var eventStartTime: Date = draft.startDate
        let defaultEndTime = Calendar.current.date(byAdding: .hour, value: 12, to: eventStartTime) ?? Date()
        var eventEndTime: Date = draft.hasEndDate ? draft.endDate : defaultEndTime
        
        // If the selected timezone is not same as current timezone, we need to convert
        // selected time to that timezone
        if draft.timezone != TimeZone.current {
            var targetCalendar = Calendar.current
            targetCalendar.timeZone = draft.timezone
            
            // Adjust start time
            let eventStartTimeComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: eventStartTime)
            if let adjustedStartTime = targetCalendar.date(from: eventStartTimeComponents) {
                eventStartTime = adjustedStartTime
            }
            
            // Adjust end time
            let eventEndTimeComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: eventEndTime)
            if let adjustedEndTime = targetCalendar.date(from: eventEndTimeComponents) {
                eventEndTime = adjustedEndTime
            }
        }
        
        let options = AmityEventCreateOptions(
            title: draft.name,
            description: draft.about,
            type: draft.location?.type ?? .inPerson,
            startTime: eventStartTime,
            endTime: eventEndTime,
            originType: .community,
            originId: targetId,
            location: draft.location?.address,
            externalUrl: draft.location?.externalPlatformUrl,
            coverImageFileId: imageData?.fileId,
            tags: nil,
            metadata: ["timezone": "\(draft.timezone.identifier)"]
        )
        
        return try await eventManager.createEvent(options: options)
    }
    
    func updateEvent(draft: EventDraft) async throws {
        var imageData: AmityImageData?
        if let avatar = draft.avatar {
            imageData = try await fileRepostiory.uploadImage(avatar, progress: nil)
        }
        
        var eventStartTime: Date = draft.startDate
        let defaultEndTime = Calendar.current.date(byAdding: .hour, value: 12, to: eventStartTime) ?? Date()
        var eventEndTime: Date = draft.hasEndDate ? draft.endDate : defaultEndTime
        
        // If the selected timezone is not same as current timezone, we need to convert
        // selected time to that timezone
        if draft.timezone != TimeZone.current {
            var targetCalendar = Calendar.current
            targetCalendar.timeZone = draft.timezone
            
            // Adjust start time
            let eventStartTimeComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: eventStartTime)
            if let adjustedStartTime = targetCalendar.date(from: eventStartTimeComponents) {
                eventStartTime = adjustedStartTime
            }
            
            // Adjust end time
            let eventEndTimeComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: eventEndTime)
            if let adjustedEndTime = targetCalendar.date(from: eventEndTimeComponents) {
                eventEndTime = adjustedEndTime
            }
        }
        
        let options = AmityEventUpdateOptions(
            title: draft.name,
            description: draft.about,
            type: draft.location?.type ?? .inPerson,
            startTime: eventStartTime,
            endTime: eventEndTime,
            location: draft.location?.address,
            externalUrl: draft.location?.externalPlatformUrl,
            coverImageFileId: imageData?.fileId,
            tags: nil,
            metadata: ["timezone": "\(draft.timezone.identifier)"]
        )
        
        try await eventManager.updateEvent(eventId: event?.eventId ?? "", options: options)
    }
}
