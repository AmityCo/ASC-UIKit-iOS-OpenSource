//
//  AmityTheme.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/23/23.
//

import UIKit

enum AmityTheme: String {
    case light = "light_theme"
    case dark = "dark_theme"
}

struct AmityThemeColor: Codable {
    var primaryColor: UIColor
    var secondaryColor: UIColor
    
    enum CodingKeys: String, CodingKey {
        case primaryColor = "primary_color"
        case secondaryColor = "secondary_color"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        primaryColor = try container.decodeUIColor(forKey: .primaryColor)
        secondaryColor = try container.decodeUIColor(forKey: .secondaryColor)
    }
    
    func encode(to encoder: Encoder) throws {}
}
