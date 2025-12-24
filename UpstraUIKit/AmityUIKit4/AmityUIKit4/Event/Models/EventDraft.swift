//
//  EventDraft.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 15/10/25.
//

import SwiftUI
import AmitySDK

class EventDraft: ObservableObject, Equatable {
    
    @Published var name: String = ""
    @Published var about: String = ""
    
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date()
    @Published var hasEndDate: Bool = true
    
    @Published var location: EventLocation?
    @Published var timezone: TimeZone = TimeZone.current
    
    @Published var avatar: UIImage?
    var avatarUrl: String?
    var isAvatarChanged = false
    
    init(name: String = "",
         about: String = "") {
        self.name = name
        self.about = about
        self.startDate = setupStartTime()
        self.endDate = setupEndTime()
    }
    
    init(event: AmityEvent) {
        self.name = event.title
        self.about = event.description
        self.hasEndDate = true
        self.avatarUrl = event.coverImage?.mediumFileURL
        
        let eventType = event.type
        let externalUrl = event.externalUrl?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let address = event.location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        var eventPlatform: EventPlatform = .livestream
        if eventType == .virtual && !externalUrl.isEmpty {
            eventPlatform = .external
        }
        
        let timezoneMetadata = event.metadata?["timezone"] as? String ?? ""
        self.timezone = TimeZone(identifier: timezoneMetadata) ?? .current
        
        // If the selected timezone was not the same as current timezone, we need to convert it from that timezone to our current timezone while editing.
        if timezone != TimeZone.current {
            // selected calendar
            var fromCalendar = Calendar.current
            fromCalendar.timeZone = timezone
            
            // current calendar
            let toCalendar = Calendar.current
                        
            let eventStartTimeComponents = fromCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: event.startTime)
            
            if let adjustedStartTime = toCalendar.date(from: eventStartTimeComponents) {
                self.startDate = adjustedStartTime
            }
            
            // Adjust end time
            let eventEndTimeComponents = fromCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: event.endTime)
            if let adjustedEndTime = toCalendar.date(from: eventEndTimeComponents) {
                self.endDate = adjustedEndTime
            }
        } else {
            self.startDate = event.startTime
            self.endDate = event.endTime
        }
        
        self.location = EventLocation(type: eventType, platform: eventPlatform, address: address, externalPlatformUrl: externalUrl)
    }
    
    static func == (lhs: EventDraft, rhs: EventDraft) -> Bool {
        return lhs.name == rhs.name
        && lhs.about == rhs.about
        && lhs.startDate == rhs.startDate
        && lhs.endDate == rhs.endDate
        && lhs.hasEndDate == rhs.hasEndDate
        && lhs.location == rhs.location
        && lhs.timezone == rhs.timezone
        && lhs.isAvatarChanged == rhs.isAvatarChanged
    }
    
    func setupStartTime() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        if let day = components.day {
            components.day = day + 1
        }
        components.hour = 9
        components.minute = 0
        components.second = 0
        
        let startTime = calendar.date(from: components)
        return startTime ?? Date()
    }
    
    func setupEndTime() -> Date {
        let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)!
        return endTime
    }
    
    var locationValue: String?  {
        guard let location else { return nil }
        
        switch location.type {
        case .virtual:
            if location.platform == .external {
                return location.externalPlatformUrl
            } else {
                return location.platform.rawValue
            }
        case .inPerson:
            return location.address
        }
    }
    
    func hasChanges(with draft: EventDraft = EventDraft()) -> Bool {
        return self != draft
    }
    
    func isEventStartTimeValid() -> Bool {
        // Event start date should be current time + 15 minutes
        let current = Date()
        let validTime = Calendar.current.date(byAdding: .minute, value: 15, to: current)!
        
        return startDate >= validTime
    }
}
