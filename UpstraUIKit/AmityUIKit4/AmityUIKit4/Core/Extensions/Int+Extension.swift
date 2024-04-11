//
//  Int+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/30/24.
//

import Foundation

private extension Double {
    func reduceScale(to places: Int) -> Double {
        let multiplier = pow(10, Double(places))
        let newDecimal = multiplier * self // move the decimal right
        let truncated = Double(Int(newDecimal)) // drop the fraction
        let originalDecimal = truncated / multiplier // move the decimal back
        return originalDecimal
    }
}

extension Int {
    // Investigate & remove this to use method below
    public var formattedCountString: String {
        if self < 1000 {
            return "\(self)"
        } else {
            let kCount = Double(self) / 1000.0
            return String(format: "%.1fK", kCount)
        }
    }
    
    func formattedCompactString() -> String {
        let n = self
        let num = abs(Double(n))
        let sign = (n < 0) ? "-" : ""

        switch num {
        case 1_000_000_000...:
            var formatted = num / 1_000_000_000
            formatted = formatted.reduceScale(to: 1)
            return "\(sign)\(formatted)B"

        case 1_000_000...:
            var formatted = num / 1_000_000
            formatted = formatted.reduceScale(to: 1)
            return "\(sign)\(formatted)M"

        case 1_000...:
            var formatted = num / 1_000
            formatted = formatted.reduceScale(to: 1)
            return "\(sign)\(formatted)K"

        case 0...:
            return "\(n)"

        default:
            return "\(sign)\(n)"
        }
    }
}
