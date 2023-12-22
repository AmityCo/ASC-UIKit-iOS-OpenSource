//
//  AmityColor.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/28/23.
//

import SwiftUI
import UIKit

enum AmityColor: String {
    case secondaryColor = "#898E9E"
    case darkGray = "#292B32"
    
    func getColor() -> Color {
        return Color(UIColor(hex: self.rawValue))
    }
}
