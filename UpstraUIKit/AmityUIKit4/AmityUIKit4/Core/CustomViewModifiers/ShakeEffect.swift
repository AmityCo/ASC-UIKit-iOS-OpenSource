//
//  ShakeEffect.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 4/4/25.
//

import SwiftUI

struct ShakeEffect: GeometryEffect {
    var position: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat = 1

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            position * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}
