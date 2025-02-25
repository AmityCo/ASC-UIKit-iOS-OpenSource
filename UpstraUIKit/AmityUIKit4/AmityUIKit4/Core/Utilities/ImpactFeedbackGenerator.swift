//
//  ImpactFeedbackGenerator.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/25/24.
//

import UIKit

class ImpactFeedbackGenerator {
    static func impactFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
