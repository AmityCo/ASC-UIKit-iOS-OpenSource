//
//  Codable+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/24/23.
//

import UIKit

extension KeyedDecodingContainer {
    func decodeUIColor(forKey key: KeyedDecodingContainer.Key) throws -> UIColor {
        let hexString = try decode(String.self, forKey: key)
        return UIColor(hex: hexString)
    }
}
