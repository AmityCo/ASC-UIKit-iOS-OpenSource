//
//  MediaAspectRatio.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/5/26.
//

import CoreGraphics

/// The three frame ratios a post carousel can use. The set is closed — no other value is permitted.
enum MediaAspectRatio {
    case landscape  // 16:9
    case square     // 1:1
    case portrait   // 4:5

    var value: CGFloat {
        switch self {
        case .landscape: return 16.0 / 9.0
        case .square: return 1.0
        case .portrait: return 0.8
        }
    }

    func height(forWidth width: CGFloat) -> CGFloat {
        width / value
    }
}

/// Classifies pixel dimensions into one of the three carousel ratios.
///
/// A threshold band, not a `W > H` comparison: both thresholds sit outside the square zone, so `1.250`
/// is landscape and `0.800` is portrait. The case that matters is `1000 x 900` (`1.111`) — wider than
/// tall but square, because classifying it landscape would crop 37% of its height away.
enum MediaRatioClassifier {

    /// Ordered conditions — the order is part of the rule.
    static func classify(width: CGFloat, height: CGFloat) -> MediaAspectRatio {
        guard width > 0, height > 0 else { return .square }

        let ratio = width / height

        if ratio >= 1.25 { return .landscape }
        if ratio <= 0.80 { return .portrait }
        return .square
    }

    static func classify(size: CGSize) -> MediaAspectRatio {
        classify(width: size.width, height: size.height)
    }
}
