//
//  Date+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/30/24.
//

import Foundation

extension Date {
    
    static var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }()
    
    public var timeAgoString: String {
        let currentDate = Date()
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.hour, .minute], from: self, to: currentDate)
        
        if let hour = components.hour, hour > 0 {
            return "\(hour)h"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m"
        } else {
            return "Just now"
        }
    }
    
}
