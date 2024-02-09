//
//  Int+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/30/24.
//

import Foundation

extension Int {
    public var formattedCountString: String {
        if self < 1000 {
            return "\(self)"
        } else {
            let kCount = Double(self) / 1000.0
            return String(format: "%.1fK", kCount)
        }
    }
}
