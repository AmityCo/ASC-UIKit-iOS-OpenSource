//
//  AdTimeWindowTracker.swift
//  AmityUIKit4
//
//  Created by Nishan on 16/6/2567 BE.
//

import Foundation
import AmitySDK

// If AdFrequency type for the placement is 'time-window', mark ad-placement seen in the current time-window.
// Note:
// AmityAdFrequency
// - type: "fixed" | "time-window"
// * fixed: 1 ads after every x posts
// * time-window: In x time-frame 1 ads will appear
class AdTimeWindowTracker {
    
    // Note:
    // Suppose we need to display ads every 5 minutes; Inorder to track whether ads is already shown or not within the given time frame, we use the concept of fixed window bucket.
    // 1. Based on the window settings, we create a bucket of time frames for each day.
    // Example: If you want to show ads every 5 minutes, we create 288 buckets per day i.e 1440 minutes in a day / 5
    // 2. If we want to mark ads being shown for particular timestamp, we determine the bucket for that timestamp.
    // Example: Get the current time and determine the index of bucket for this time.
    typealias WindowKey = String
    
    private var formatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()
        
    private var markedTimeWindow = [AmityAdPlacement: WindowKey]()
    
    public func hasReachedTimeWindowLimit(placement: AmityAdPlacement) -> Bool {
        let windowKey = getCurrentWindowKey(placement: placement)
        return markedTimeWindow[placement] == windowKey
    }
    
    public func markAsSeen(placement: AmityAdPlacement) {
        markedTimeWindow[placement] = getCurrentWindowKey(placement: placement)
    }

    public func clear() {
        markedTimeWindow = [:]
    }
    
    // Let there be an index, windowIndex, for each time-window during a day.
    private func getCurrentWindowKey(placement: AmityAdPlacement) -> String {
        let windowSizeInMinutes = getTimeWindowSettings(placement: placement)
        let windowIndex = getMinutesElapsed() / windowSizeInMinutes
        let today = formatter.string(from: Date())
        return "\(today)-\(windowIndex)"
    }
    
    // Total minutes since start of day
    private func getMinutesElapsed() -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0

        let totalMinutes = hours * 60 + minutes
        return totalMinutes
    }
    
    private func getTimeWindowSettings(placement: AmityAdPlacement) -> Int {
        if let adFrequency = AdEngine.shared.getAdFrequency(at: placement), adFrequency.isTypeTimeWindow {
            return adFrequency.value
        }
        return 0
    }
}
