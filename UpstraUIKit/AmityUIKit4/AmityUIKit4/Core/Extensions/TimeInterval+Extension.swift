//
//  TimeInterval+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/11/24.
//

import Foundation

extension TimeInterval {
    var formattedDurationString: String? {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = self >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: self)
    }
}
