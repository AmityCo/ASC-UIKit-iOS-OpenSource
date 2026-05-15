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
    
    var timeAgoString: String {
        let currentDate = Date()
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.hour, .minute], from: self, to: currentDate)
        
        let hSuffix = AmityLocalizedStringSet.General.timeHoursSuffix.localizedString
        let mSuffix = AmityLocalizedStringSet.General.timeMinutesSuffix.localizedString
        
        if let hour = components.hour, hour > 0 {
            return "\(hour)\(hSuffix)"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)\(mSuffix)"
        } else {
            return AmityLocalizedStringSet.General.justNow.localizedString
        }
    }
            var yearsFromNow: Int {
                let startComponents =  Calendar.current.dateComponents([.year, .month, .day], from: self)
                let endComponents =  Calendar.current.dateComponents([.year, .month, .day], from: Date())
                return (endComponents.year ?? 0) - (startComponents.year ?? 0)
            }
            var monthsFromNow: Int {
                return Calendar.current.dateComponents([.month], from: self, to: Date()).month!
            }
            var weeksFromNow: Int {
                return Calendar.current.dateComponents([.weekOfYear], from: self, to: Date()).weekOfYear!
            }
            var daysFromNow: Int {
                return Calendar.current.dateComponents([.day], from: self, to: Date()).day!
            }
            var isInYesterday: Bool {
                return Calendar.current.isDateInYesterday(self)
            }
            var hoursFromNow: Int {
                return Calendar.current.dateComponents([.hour], from: self, to: Date()).hour!
            }
            var minutesFromNow: Int {
                return Calendar.current.dateComponents([.minute], from: self, to: Date()).minute!
            }
            var secondsFromNow: Int {
                return Calendar.current.dateComponents([.second], from: self, to: Date()).second!
            }
            
            var relativeTime: String {
                let dateFormatter = DateFormatter()
                
                let dSuffix = AmityLocalizedStringSet.General.timeDaysSuffix.localizedString
                let hSuffix = AmityLocalizedStringSet.General.timeHoursSuffix.localizedString
                let mSuffix = AmityLocalizedStringSet.General.timeMinutesSuffix.localizedString
                
                if yearsFromNow > 0 {
                    dateFormatter.dateFormat = "d MMM yyyy"
                    return dateFormatter.string(from: self)
                }
                if monthsFromNow > 0 {
                    dateFormatter.dateFormat = "d MMM"
                    return dateFormatter.string(from: self)
                }
                if weeksFromNow > 0 {
                    dateFormatter.dateFormat = "d MMM"
                    return dateFormatter.string(from: self)
                }
                if daysFromNow > 0 {
                    return "\(daysFromNow)\(dSuffix)"
                }
                if hoursFromNow > 0 {
                    return "\(hoursFromNow)\(hSuffix)"
                }
                if minutesFromNow > 0 {
                    return "\(minutesFromNow)\(mSuffix)"
                }
                return AmityLocalizedStringSet.General.justNow.localizedString
            }
        }
