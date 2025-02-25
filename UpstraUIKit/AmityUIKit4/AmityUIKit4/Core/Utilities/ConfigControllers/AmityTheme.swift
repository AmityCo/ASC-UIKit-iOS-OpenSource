//
//  AmityTheme.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/23/23.
//

import UIKit
import SwiftUI

let lightTheme = AmityTheme(primaryColor: UIColor(hex: "#1054DE"),
                            secondaryColor: UIColor(hex: "#292B32"),
                            baseColor: UIColor(hex: "#292B32"),
                            baseInverseColor: UIColor(hex: "#292B32"),
                            baseColorShade1: UIColor(hex: "#636878"),
                            baseColorShade2: UIColor(hex: "#898E9E"),
                            baseColorShade3: UIColor(hex: "#A5A9b5"),
                            baseColorShade4: UIColor(hex: "#EBECEF"),
                            alertColor: UIColor(hex: "#FA4D30"),
                            backgroundColor: UIColor(hex: "#FFFFFF"),
                            backgroundShade1Color: UIColor(hex: "#F6F7F8"),
                            highlightColor: UIColor(hex: "1054DE")
)

let darkTheme = AmityTheme(primaryColor: UIColor(hex: "#1054DE"),
                           secondaryColor: UIColor(hex: "#292B32"),
                           baseColor: UIColor(hex: "#EBECEF"),
                           baseInverseColor: UIColor(hex: "#FFFFFF"),
                           baseColorShade1: UIColor(hex: "#A5A9B5"),
                           baseColorShade2: UIColor(hex: "#6E7487"),
                           baseColorShade3: UIColor(hex: "#40434E"),
                           baseColorShade4: UIColor(hex: "#292B32"),
                           alertColor: UIColor(hex: "#FA4D30"),
                           backgroundColor: UIColor(hex: "#191919"),
                           backgroundShade1Color: UIColor(hex: "#40434E"),
                           highlightColor: UIColor(hex: "1054DE")
)

enum AmityThemeStyle: String {
    case system = "default"
    case light = "light"
    case dark = "dark"
}

struct AmityTheme: Codable {
    let primaryColor: UIColor?
    let secondaryColor: UIColor?
    let baseColor: UIColor?
    let baseInverseColor: UIColor?
    let baseColorShade1: UIColor?
    let baseColorShade2: UIColor?
    let baseColorShade3: UIColor?
    let baseColorShade4: UIColor?
    let alertColor: UIColor?
    let backgroundColor: UIColor?
    let backgroundShade1Color: UIColor?
    let highlightColor: UIColor?
    
    public init(primaryColor: UIColor, 
                secondaryColor: UIColor,
                baseColor: UIColor,
                baseInverseColor: UIColor,
                baseColorShade1: UIColor,
                baseColorShade2: UIColor,
                baseColorShade3: UIColor,
                baseColorShade4: UIColor,
                alertColor: UIColor,
                backgroundColor: UIColor,
                backgroundShade1Color: UIColor,
                highlightColor: UIColor
    ) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.baseColor = baseColor
        self.baseInverseColor = baseInverseColor
        self.baseColorShade1 = baseColorShade1
        self.baseColorShade2 = baseColorShade2
        self.baseColorShade3 = baseColorShade3
        self.baseColorShade4 = baseColorShade4
        self.alertColor = alertColor
        self.backgroundColor = backgroundColor
        self.backgroundShade1Color = backgroundShade1Color
        self.highlightColor = highlightColor
    }
    
    enum CodingKeys: String, CodingKey {
        case primaryColor = "primary_color"
        case secondaryColor = "secondary_color"
        case baseColor = "base_color"
        case baseColorShade1 = "base_shade1_color"
        case baseColorShade2 = "base_shade2_color"
        case baseColorShade3 = "base_shade3_color"
        case baseColorShade4 = "base_shade4_color"
        case alertColor = "alert_color"
        case backgroundColor = "background_color"
        case baseInverseColor = "base_inverse_color"
        case backgroundShade1Color = "background_shade1_color"
        case highlightColor = "highlight_color"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        primaryColor = try? container.decodeUIColor(forKey: .primaryColor)
        secondaryColor = try? container.decodeUIColor(forKey: .secondaryColor)
        baseColor = try? container.decodeUIColor(forKey: .baseColor)
        baseColorShade1 = try? container.decodeUIColor(forKey: .baseColorShade1)
        baseColorShade2 = try? container.decodeUIColor(forKey: .baseColorShade2)
        baseColorShade3 = try? container.decodeUIColor(forKey: .baseColorShade3)
        baseColorShade4 = try? container.decodeUIColor(forKey: .baseColorShade4)
        alertColor = try? container.decodeUIColor(forKey: .alertColor)
        backgroundColor = try? container.decodeUIColor(forKey: .backgroundColor)
        baseInverseColor = try? container.decodeUIColor(forKey: .baseInverseColor)
        backgroundShade1Color = try? container.decodeUIColor(forKey: .backgroundShade1Color)
        highlightColor = try? container.decodeUIColor(forKey: .highlightColor)
    }
    
    public func encode(to encoder: Encoder) throws {}
}

struct AmityThemeColor {
    var primaryColor: UIColor
    var secondaryColor: UIColor
    var baseColor: UIColor
    var baseColorShade1: UIColor
    var baseColorShade2: UIColor
    var baseColorShade3: UIColor
    var baseColorShade4: UIColor
    var alertColor: UIColor
    var backgroundColor: UIColor
    var baseInverseColor: UIColor
    var backgroundShade1Color: UIColor
    var highlightColor: UIColor
}

