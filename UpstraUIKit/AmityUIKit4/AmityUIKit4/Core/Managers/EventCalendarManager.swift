//
//  EventCalendarManager.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 17/11/25.
//

import SwiftUI
import EventKit
import AmitySDK

class EventCalendarManager {
    
    let store = EKEventStore()
    
    func requestPermission(onCompletion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            store.requestWriteOnlyAccessToEvents { isGranted, error in
                if let error {
                    onCompletion(false)
                    return
                }
                
                onCompletion(isGranted)
            }
        } else {
            store.requestAccess(to: .event) { isGranted, error in
                if let error {
                    onCompletion(false)
                    return
                }
                
                onCompletion(isGranted)
            }
        }
    }
    
    func addEvent(event: AmityEvent) {
        let calendarEvent = EKEvent(eventStore: store)
        calendarEvent.title = event.title
        calendarEvent.startDate = event.startTime
        calendarEvent.endDate = event.endTime
        calendarEvent.timeZone = .current
        calendarEvent.notes = event.description
        calendarEvent.calendar = store.defaultCalendarForNewEvents

        do {
            try store.save(calendarEvent, span: .thisEvent)
            Log.add("Event added to calendar")
        } catch {
            Log.warn("Failed to add event")
        }
    }
}
