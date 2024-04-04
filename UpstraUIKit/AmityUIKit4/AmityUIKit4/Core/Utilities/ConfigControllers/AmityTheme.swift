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
                            baseColorShade1: UIColor(hex: "#636878"),
                            baseColorShade2: UIColor(hex: "#898E9E"),
                            baseColorShade3: UIColor(hex: "#A5A9b5"),
                            baseColorShade4: UIColor(hex: "#EBECEF"),
                            alertColor: UIColor(hex: "#FA4D30"),
                            backgroundColor: UIColor(hex: "#FFFFFF"))

let darkTheme = AmityTheme(primaryColor: UIColor(hex: "#1054DE"),
                           secondaryColor: UIColor(hex: "#292B32"),
                           baseColor: UIColor(hex: "#EBECEF"),
                           baseColorShade1: UIColor(hex: "#A5A9B5"),
                           baseColorShade2: UIColor(hex: "#6E7487"),
                           baseColorShade3: UIColor(hex: "#40434E"),
                           baseColorShade4: UIColor(hex: "#292B32"),
                           alertColor: UIColor(hex: "#FA4D30"),
                           backgroundColor: UIColor(hex: "#191919"))

enum AmityThemeStyle: String {
    case system = "default"
    case light = "light"
    case dark = "dark"
}

struct AmityTheme: Codable {
    var primaryColor: UIColor?
    var secondaryColor: UIColor?
    var baseColor: UIColor?
    var baseColorShade1: UIColor?
    var baseColorShade2: UIColor?
    var baseColorShade3: UIColor?
    var baseColorShade4: UIColor?
    var alertColor: UIColor?
    var backgroundColor: UIColor?
    
    public init(primaryColor: UIColor, 
                secondaryColor: UIColor,
                baseColor: UIColor,
                baseColorShade1: UIColor,
                baseColorShade2: UIColor,
                baseColorShade3: UIColor,
                baseColorShade4: UIColor,
                alertColor: UIColor,
                backgroundColor: UIColor) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.baseColor = baseColor
        self.baseColorShade1 = baseColorShade1
        self.baseColorShade2 = baseColorShade2
        self.baseColorShade3 = baseColorShade3
        self.baseColorShade4 = baseColorShade4
        self.alertColor = alertColor
        self.backgroundColor = backgroundColor
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
}

