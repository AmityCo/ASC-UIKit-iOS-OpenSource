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
    
    public var formattedCountString: String {
        let n = self
        let num = abs(Double(n))

        switch num {
        case 1_000_000_000...:
            guard num > 1_100_000_000 else {
                return "1B"
            }
            
            let kCount = Double(self) / 1_000_000_000
            return "\(Formatters.countFormatter.string(from: NSNumber(value: kCount)) ?? "")B" // Format value to make 10.0B -> 10B

        case 1_000_000...:
            guard num > 1_100_000 else {
                return "1M"
            }
            
            let kCount = Double(self) / 1_000_000
            return "\(Formatters.countFormatter.string(from: NSNumber(value: kCount)) ?? "")M"

        case 1_000...:
            guard num > 1100 else {
                return "1K"
            }
            
            let kCount = Double(self) / 1000.0
            return "\(Formatters.countFormatter.string(from: NSNumber(value: kCount)) ?? "")K"

        case 0...:
            return "\(n)"

        default:
            return "\(n)"
        }
    }
}
