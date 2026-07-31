//
//  AmityTheme.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/23/23.
//

import UIKit
import SwiftUI

let lightTheme = AmityTheme(primaryColor: UIColor(hex: "#1054DE"),
                            primaryColorShade1: UIColor(hex: "#4A82F2"),
                            primaryColorShade2: UIColor(hex: "#A9C4F9"),
                            primaryColorShade3: UIColor(hex: "#D9E5FC"),
                            primaryColorShade4: UIColor(hex: "#1A4499"),
                            secondaryColor: UIColor(hex: "#292B32"),
                            secondaryColorShade1: UIColor(hex: "#636878"),
                            secondaryColorShade2: UIColor(hex: "#898E9E"),
                            secondaryColorShade3: UIColor(hex: "#A5A9B5"),
                            secondaryColorShade4: UIColor(hex: "#EBECEF"),
                            neutralGreyShade1Color: UIColor(hex: "#EBECEF"),
                            neutralGreyShade2Color: UIColor(hex: "#A5A9B5"),
                            neutralGreyShade3Color: UIColor(hex: "#898E9E"),
                            neutralGreyShade4Color: UIColor(hex: "#636878"),
                            neutralGreyShade5Color: UIColor(hex: "#40434E"),
                            neutralGreyShade6Color: UIColor(hex: "#292B32"),
                            baseColor: UIColor(hex: "#292B32"),
                            baseInverseColor: UIColor(hex: "#000000"),
                            baseColorShade1: UIColor(hex: "#636878"),
                            baseColorShade2: UIColor(hex: "#898E9E"),
                            baseColorShade3: UIColor(hex: "#A5A9b5"),
                            baseColorShade4: UIColor(hex: "#EBECEF"),
                            alertColor: UIColor(hex: "#FA4D30"),
                            alertColorShade1: UIColor(hex: "#FB7159"),
                            backgroundColor: UIColor(hex: "#FFFFFF"),
                            backgroundShade1Color: UIColor(hex: "#F6F7F8"),
                            highlightColor: UIColor(hex: "#1054DE"),
                            destructiveShade1Color: UIColor(hex: "#F38F96"),
                            destructiveShade2Color: UIColor(hex: "#EE5C66"),
                            destructiveShade3Color: UIColor(hex: "#EA3C49"),
                            destructiveShade4Color: UIColor(hex: "#E50B1B"),
                            destructiveShade5Color: UIColor(hex: "#A30813"),
                            transparentBlackShade1Color: UIColor(hex: "#0000004D"),
                            transparentBlackShade2Color: UIColor(hex: "#0000004D"),
                            transparentBlackShade3Color: UIColor(hex: "#00000080"),
                            transparentBlackShade4Color: UIColor(hex: "#00000099"),
                            transparentBlackShade5Color: UIColor(hex: "#000000CC"),
                            transparentWhiteShade1Color: UIColor(hex: "#FFFFFF1A"),
                            transparentWhiteShade2Color: UIColor(hex: "#FFFFFF1A"),
                            transparentWhiteShade3Color: UIColor(hex: "#FFFFFF33"),
                            transparentWhiteShade4Color: UIColor(hex: "#FFFFFF4D"),
                            transparentWhiteShade5Color: UIColor(hex: "#FFFFFF4D"),
                            transparentWhiteShade6Color: UIColor(hex: "#FFFFFF4D"),
                            transparentWhiteShade7Color: UIColor(hex: "#FFFFFF4D"),
                            transparentRedShade1Color: UIColor(hex: "#FF305A4D")
)

let darkTheme = AmityTheme(primaryColor: UIColor(hex: "#1054DE"),
                           primaryColorShade1: UIColor(hex: "#4A82F2"),
                           primaryColorShade2: UIColor(hex: "#A9C4F9"),
                           primaryColorShade3: UIColor(hex: "#D9E5FC"),
                           primaryColorShade4: UIColor(hex: "#1A4499"),
                           secondaryColor: UIColor(hex: "#EBECEF"),
                           secondaryColorShade1: UIColor(hex: "#A5A9B5"),
                           secondaryColorShade2: UIColor(hex: "#898E9E"),
                           secondaryColorShade3: UIColor(hex: "#40434E"),
                           secondaryColorShade4: UIColor(hex: "#292B32"),
                           neutralGreyShade1Color: UIColor(hex: "#EBECEF"),
                           neutralGreyShade2Color: UIColor(hex: "#A5A9B5"),
                           neutralGreyShade3Color: UIColor(hex: "#898E9E"),
                           neutralGreyShade4Color: UIColor(hex: "#636878"),
                           neutralGreyShade5Color: UIColor(hex: "#40434E"),
                           neutralGreyShade6Color: UIColor(hex: "#292B32"),
                           baseColor: UIColor(hex: "#EBECEF"),
                           baseInverseColor: UIColor(hex: "#FFFFFF"),
                           baseColorShade1: UIColor(hex: "#A5A9B5"),
                           baseColorShade2: UIColor(hex: "#6E7487"),
                           baseColorShade3: UIColor(hex: "#40434E"),
                           baseColorShade4: UIColor(hex: "#292B32"),
                           alertColor: UIColor(hex: "#FA4D30"),
                           alertColorShade1: UIColor(hex: "#FB7159"),
                           backgroundColor: UIColor(hex: "#191919"),
                           backgroundShade1Color: UIColor(hex: "#40434E"),
                           highlightColor: UIColor(hex: "#4A82F2"),
                           destructiveShade1Color: UIColor(hex: "#F38F96"),
                           destructiveShade2Color: UIColor(hex: "#EE5C66"),
                           destructiveShade3Color: UIColor(hex: "#EA3C49"),
                           destructiveShade4Color: UIColor(hex: "#E50B1B"),
                           destructiveShade5Color: UIColor(hex: "#A30813"),
                           transparentBlackShade1Color: UIColor(hex: "#0000004D"),
                           transparentBlackShade2Color: UIColor(hex: "#0000004D"),
                           transparentBlackShade3Color: UIColor(hex: "#00000080"),
                           transparentBlackShade4Color: UIColor(hex: "#00000099"),
                           transparentBlackShade5Color: UIColor(hex: "#000000CC"),
                           transparentWhiteShade1Color: UIColor(hex: "#FFFFFF1A"),
                           transparentWhiteShade2Color: UIColor(hex: "#FFFFFF1A"),
                           transparentWhiteShade3Color: UIColor(hex: "#FFFFFF33"),
                           transparentWhiteShade4Color: UIColor(hex: "#FFFFFF4D"),
                           transparentWhiteShade5Color: UIColor(hex: "#FFFFFF4D"),
                           transparentWhiteShade6Color: UIColor(hex: "#FFFFFF4D"),
                           transparentWhiteShade7Color: UIColor(hex: "#FFFFFF4D"),
                           transparentRedShade1Color: UIColor(hex: "#FF305A4D")
)

enum AmityThemeStyle: String {
    case system = "default"
    case light = "light"
    case dark = "dark"
}

struct AmityTheme: Codable {
    let primaryColor: UIColor?
    let primaryColorShade1: UIColor?
    let primaryColorShade2: UIColor?
    let primaryColorShade3: UIColor?
    let primaryColorShade4: UIColor?
    let secondaryColor: UIColor?
    let secondaryColorShade1: UIColor?
    let secondaryColorShade2: UIColor?
    let secondaryColorShade3: UIColor?
    let secondaryColorShade4: UIColor?
    let neutralGreyShade1Color: UIColor?
    let neutralGreyShade2Color: UIColor?
    let neutralGreyShade3Color: UIColor?
    let neutralGreyShade4Color: UIColor?
    let neutralGreyShade5Color: UIColor?
    let neutralGreyShade6Color: UIColor?
    let baseColor: UIColor?
    let baseInverseColor: UIColor?
    let baseColorShade1: UIColor?
    let baseColorShade2: UIColor?
    let baseColorShade3: UIColor?
    let baseColorShade4: UIColor?
    let alertColor: UIColor?
    let alertColorShade1: UIColor?
    let backgroundColor: UIColor?
    let backgroundShade1Color: UIColor?
    let highlightColor: UIColor?
    let destructiveShade1Color: UIColor?
    let destructiveShade2Color: UIColor?
    let destructiveShade3Color: UIColor?
    let destructiveShade4Color: UIColor?
    let destructiveShade5Color: UIColor?
    let transparentBlackShade1Color: UIColor?
    let transparentBlackShade2Color: UIColor?
    let transparentBlackShade3Color: UIColor?
    let transparentBlackShade4Color: UIColor?
    let transparentBlackShade5Color: UIColor?
    let transparentWhiteShade1Color: UIColor?
    let transparentWhiteShade2Color: UIColor?
    let transparentWhiteShade3Color: UIColor?
    let transparentWhiteShade4Color: UIColor?
    let transparentWhiteShade5Color: UIColor?
    let transparentWhiteShade6Color: UIColor?
    let transparentWhiteShade7Color: UIColor?
    let transparentRedShade1Color: UIColor?

    public init(primaryColor: UIColor,
                primaryColorShade1: UIColor,
                primaryColorShade2: UIColor,
                primaryColorShade3: UIColor,
                primaryColorShade4: UIColor,
                secondaryColor: UIColor,
                secondaryColorShade1: UIColor?,
                secondaryColorShade2: UIColor,
                secondaryColorShade3: UIColor,
                secondaryColorShade4: UIColor,
                neutralGreyShade1Color: UIColor,
                neutralGreyShade2Color: UIColor,
                neutralGreyShade3Color: UIColor,
                neutralGreyShade4Color: UIColor,
                neutralGreyShade5Color: UIColor,
                neutralGreyShade6Color: UIColor,
                baseColor: UIColor,
                baseInverseColor: UIColor,
                baseColorShade1: UIColor,
                baseColorShade2: UIColor,
                baseColorShade3: UIColor,
                baseColorShade4: UIColor,
                alertColor: UIColor,
                alertColorShade1: UIColor,
                backgroundColor: UIColor,
                backgroundShade1Color: UIColor,
                highlightColor: UIColor,
                destructiveShade1Color: UIColor,
                destructiveShade2Color: UIColor,
                destructiveShade3Color: UIColor,
                destructiveShade4Color: UIColor,
                destructiveShade5Color: UIColor,
                transparentBlackShade1Color: UIColor,
                transparentBlackShade2Color: UIColor,
                transparentBlackShade3Color: UIColor,
                transparentBlackShade4Color: UIColor,
                transparentBlackShade5Color: UIColor,
                transparentWhiteShade1Color: UIColor,
                transparentWhiteShade2Color: UIColor,
                transparentWhiteShade3Color: UIColor,
                transparentWhiteShade4Color: UIColor,
                transparentWhiteShade5Color: UIColor,
                transparentWhiteShade6Color: UIColor,
                transparentWhiteShade7Color: UIColor,
                transparentRedShade1Color: UIColor
    ) {
        self.primaryColor = primaryColor
        self.primaryColorShade1 = primaryColorShade1
        self.primaryColorShade2 = primaryColorShade2
        self.primaryColorShade3 = primaryColorShade3
        self.primaryColorShade4 = primaryColorShade4
        self.secondaryColor = secondaryColor
        self.secondaryColorShade1 = secondaryColorShade1
        self.secondaryColorShade2 = secondaryColorShade2
        self.secondaryColorShade3 = secondaryColorShade3
        self.secondaryColorShade4 = secondaryColorShade4
        self.neutralGreyShade1Color = neutralGreyShade1Color
        self.neutralGreyShade2Color = neutralGreyShade2Color
        self.neutralGreyShade3Color = neutralGreyShade3Color
        self.neutralGreyShade4Color = neutralGreyShade4Color
        self.neutralGreyShade5Color = neutralGreyShade5Color
        self.neutralGreyShade6Color = neutralGreyShade6Color
        self.baseColor = baseColor
        self.baseInverseColor = baseInverseColor
        self.baseColorShade1 = baseColorShade1
        self.baseColorShade2 = baseColorShade2
        self.baseColorShade3 = baseColorShade3
        self.baseColorShade4 = baseColorShade4
        self.alertColor = alertColor
        self.alertColorShade1 = alertColorShade1
        self.backgroundColor = backgroundColor
        self.backgroundShade1Color = backgroundShade1Color
        self.highlightColor = highlightColor
        self.destructiveShade1Color = destructiveShade1Color
        self.destructiveShade2Color = destructiveShade2Color
        self.destructiveShade3Color = destructiveShade3Color
        self.destructiveShade4Color = destructiveShade4Color
        self.destructiveShade5Color = destructiveShade5Color
        self.transparentBlackShade1Color = transparentBlackShade1Color
        self.transparentBlackShade2Color = transparentBlackShade2Color
        self.transparentBlackShade3Color = transparentBlackShade3Color
        self.transparentBlackShade4Color = transparentBlackShade4Color
        self.transparentBlackShade5Color = transparentBlackShade5Color
        self.transparentWhiteShade1Color = transparentWhiteShade1Color
        self.transparentWhiteShade2Color = transparentWhiteShade2Color
        self.transparentWhiteShade3Color = transparentWhiteShade3Color
        self.transparentWhiteShade4Color = transparentWhiteShade4Color
        self.transparentWhiteShade5Color = transparentWhiteShade5Color
        self.transparentWhiteShade6Color = transparentWhiteShade6Color
        self.transparentWhiteShade7Color = transparentWhiteShade7Color
        self.transparentRedShade1Color = transparentRedShade1Color
    }

    enum CodingKeys: String, CodingKey {
        case primaryColor = "primary_color"
        case primaryColorShade1 = "primary_shade1_color"
        case primaryColorShade2 = "primary_shade2_color"
        case primaryColorShade3 = "primary_shade3_color"
        case primaryColorShade4 = "primary_shade4_color"
        case secondaryColor = "secondary_color"
        case secondaryColorShade1 = "secondary_shade1_color"
        case secondaryColorShade2 = "secondary_shade2_color"
        case secondaryColorShade3 = "secondary_shade3_color"
        case secondaryColorShade4 = "secondary_shade4_color"
        case neutralGreyShade1Color = "neutral_grey_shade1_color"
        case neutralGreyShade2Color = "neutral_grey_shade2_color"
        case neutralGreyShade3Color = "neutral_grey_shade3_color"
        case neutralGreyShade4Color = "neutral_grey_shade4_color"
        case neutralGreyShade5Color = "neutral_grey_shade5_color"
        case neutralGreyShade6Color = "neutral_grey_shade6_color"
        case baseColor = "base_color"
        case baseColorShade1 = "base_shade1_color"
        case baseColorShade2 = "base_shade2_color"
        case baseColorShade3 = "base_shade3_color"
        case baseColorShade4 = "base_shade4_color"
        case alertColor = "alert_color"
        case alertColorShade1 = "alert_shade1_color"
        case backgroundColor = "background_color"
        case baseInverseColor = "base_inverse_color"
        case backgroundShade1Color = "background_shade1_color"
        case highlightColor = "highlight_color"
        case destructiveShade1Color = "destructive_shade1_color"
        case destructiveShade2Color = "destructive_shade2_color"
        case destructiveShade3Color = "destructive_shade3_color"
        case destructiveShade4Color = "destructive_shade4_color"
        case destructiveShade5Color = "destructive_shade5_color"
        case transparentBlackShade1Color = "transparent_black_shade1_color"
        case transparentBlackShade2Color = "transparent_black_shade2_color"
        case transparentBlackShade3Color = "transparent_black_shade3_color"
        case transparentBlackShade4Color = "transparent_black_shade4_color"
        case transparentBlackShade5Color = "transparent_black_shade5_color"
        case transparentWhiteShade1Color = "transparent_white_shade1_color"
        case transparentWhiteShade2Color = "transparent_white_shade2_color"
        case transparentWhiteShade3Color = "transparent_white_shade3_color"
        case transparentWhiteShade4Color = "transparent_white_shade4_color"
        case transparentWhiteShade5Color = "transparent_white_shade5_color"
        case transparentWhiteShade6Color = "transparent_white_shade6_color"
        case transparentWhiteShade7Color = "transparent_white_shade7_color"
        case transparentRedShade1Color = "transparent_red_shade1_color"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        primaryColor = try? container.decodeUIColor(forKey: .primaryColor)
        primaryColorShade1 = try? container.decodeUIColor(forKey: .primaryColorShade1)
        primaryColorShade2 = try? container.decodeUIColor(forKey: .primaryColorShade2)
        primaryColorShade3 = try? container.decodeUIColor(forKey: .primaryColorShade3)
        primaryColorShade4 = try? container.decodeUIColor(forKey: .primaryColorShade4)
        secondaryColor = try? container.decodeUIColor(forKey: .secondaryColor)
        secondaryColorShade1 = (try? container.decodeUIColor(forKey: .secondaryColorShade1)) ?? UIColor(hex: "636878")
        secondaryColorShade2 = try? container.decodeUIColor(forKey: .secondaryColorShade2)
        secondaryColorShade3 = try? container.decodeUIColor(forKey: .secondaryColorShade3)
        secondaryColorShade4 = try? container.decodeUIColor(forKey: .secondaryColorShade4)
        neutralGreyShade1Color = try? container.decodeUIColor(forKey: .neutralGreyShade1Color)
        neutralGreyShade2Color = try? container.decodeUIColor(forKey: .neutralGreyShade2Color)
        neutralGreyShade3Color = try? container.decodeUIColor(forKey: .neutralGreyShade3Color)
        neutralGreyShade4Color = try? container.decodeUIColor(forKey: .neutralGreyShade4Color)
        neutralGreyShade5Color = try? container.decodeUIColor(forKey: .neutralGreyShade5Color)
        neutralGreyShade6Color = try? container.decodeUIColor(forKey: .neutralGreyShade6Color)
        baseColor = try? container.decodeUIColor(forKey: .baseColor)
        baseColorShade1 = try? container.decodeUIColor(forKey: .baseColorShade1)
        baseColorShade2 = try? container.decodeUIColor(forKey: .baseColorShade2)
        baseColorShade3 = try? container.decodeUIColor(forKey: .baseColorShade3)
        baseColorShade4 = try? container.decodeUIColor(forKey: .baseColorShade4)
        alertColor = try? container.decodeUIColor(forKey: .alertColor)
        alertColorShade1 = try? container.decodeUIColor(forKey: .alertColorShade1)
        backgroundColor = try? container.decodeUIColor(forKey: .backgroundColor)
        baseInverseColor = try? container.decodeUIColor(forKey: .baseInverseColor)
        backgroundShade1Color = try? container.decodeUIColor(forKey: .backgroundShade1Color)
        highlightColor = try? container.decodeUIColor(forKey: .highlightColor)
        destructiveShade1Color = try? container.decodeUIColor(forKey: .destructiveShade1Color)
        destructiveShade2Color = try? container.decodeUIColor(forKey: .destructiveShade2Color)
        destructiveShade3Color = try? container.decodeUIColor(forKey: .destructiveShade3Color)
        destructiveShade4Color = try? container.decodeUIColor(forKey: .destructiveShade4Color)
        destructiveShade5Color = try? container.decodeUIColor(forKey: .destructiveShade5Color)
        transparentBlackShade1Color = try? container.decodeUIColor(forKey: .transparentBlackShade1Color)
        transparentBlackShade2Color = try? container.decodeUIColor(forKey: .transparentBlackShade2Color)
        transparentBlackShade3Color = try? container.decodeUIColor(forKey: .transparentBlackShade3Color)
        transparentBlackShade4Color = try? container.decodeUIColor(forKey: .transparentBlackShade4Color)
        transparentBlackShade5Color = try? container.decodeUIColor(forKey: .transparentBlackShade5Color)
        transparentWhiteShade1Color = try? container.decodeUIColor(forKey: .transparentWhiteShade1Color)
        transparentWhiteShade2Color = try? container.decodeUIColor(forKey: .transparentWhiteShade2Color)
        transparentWhiteShade3Color = try? container.decodeUIColor(forKey: .transparentWhiteShade3Color)
        transparentWhiteShade4Color = try? container.decodeUIColor(forKey: .transparentWhiteShade4Color)
        transparentWhiteShade5Color = try? container.decodeUIColor(forKey: .transparentWhiteShade5Color)
        transparentWhiteShade6Color = try? container.decodeUIColor(forKey: .transparentWhiteShade6Color)
        transparentWhiteShade7Color = try? container.decodeUIColor(forKey: .transparentWhiteShade7Color)
        transparentRedShade1Color = try? container.decodeUIColor(forKey: .transparentRedShade1Color)
    }

    public func encode(to encoder: Encoder) throws {}
}

struct AmityThemeColor {
    var primaryColor: UIColor
    var primaryColorShade1: UIColor
    var primaryColorShade2: UIColor
    var primaryColorShade3: UIColor
    var primaryColorShade4: UIColor
    var secondaryColor: UIColor
    let secondaryColorShade1: UIColor
    var secondaryColorShade2: UIColor
    var secondaryColorShade3: UIColor
    var secondaryColorShade4: UIColor
    var neutralGreyShade1Color: UIColor
    var neutralGreyShade2Color: UIColor
    var neutralGreyShade3Color: UIColor
    var neutralGreyShade4Color: UIColor
    var neutralGreyShade5Color: UIColor
    var neutralGreyShade6Color: UIColor
    var baseColor: UIColor
    var baseColorShade1: UIColor
    var baseColorShade2: UIColor
    var baseColorShade3: UIColor
    var baseColorShade4: UIColor
    var alertColor: UIColor
    var alertColorShade1: UIColor
    var backgroundColor: UIColor
    var baseInverseColor: UIColor
    var backgroundShade1Color: UIColor
    var highlightColor: UIColor
    var destructiveShade1Color: UIColor
    var destructiveShade2Color: UIColor
    var destructiveShade3Color: UIColor
    var destructiveShade4Color: UIColor
    var destructiveShade5Color: UIColor
    var transparentBlackShade1Color: UIColor
    var transparentBlackShade2Color: UIColor
    var transparentBlackShade3Color: UIColor
    var transparentBlackShade4Color: UIColor
    var transparentBlackShade5Color: UIColor
    var transparentWhiteShade1Color: UIColor
    var transparentWhiteShade2Color: UIColor
    var transparentWhiteShade3Color: UIColor
    var transparentWhiteShade4Color: UIColor
    var transparentWhiteShade5Color: UIColor
    var transparentWhiteShade6Color: UIColor
    var transparentWhiteShade7Color: UIColor
    var transparentRedShade1Color: UIColor
}

/// Fixed colors kept out of the JSON theme config. Mostly brand colors identical in light &
/// dark; also a few internal theme-aware surfaces. Use directly instead of `viewConfig.theme`.
class AmityFixedColor {
    static let shared = AmityFixedColor()
    private init() {}

    let live = UIColor(hex: "#FF305A")
    let eventHost = UIColor(hex: "#4B1BD0")
    let eventHostBg = UIColor(hex: "#EAE2FF")
    let storyRingProgress: [UIColor] = [UIColor(hex: "#339AF9"), UIColor(hex: "#78FA58")]
    let speakerButtonBackground = UIColor(hex: "#6A6A6B")
    let white = UIColor.white
    let black = UIColor.black
    let greyShade4 = UIColor(hex: "#EBECEF")
    let greyShade1 = UIColor(hex: "#636878")

    /// Toast background — dark surface in both modes so white toast text stays readable.
    var toastBackground: UIColor {
        AmityUIKitConfigController.shared.getCurrentThemeStyle() == .dark ? UIColor(hex: "#40434E") : UIColor(hex: "#292B32")
    }

    /// End-of-feed ("caught up") icon — grey shade 4 in light, grey shade 1 in dark.
    var feedCaughtUpIcon: UIColor {
        AmityUIKitConfigController.shared.getCurrentThemeStyle() == .dark ? greyShade1 : greyShade4
    }
}
