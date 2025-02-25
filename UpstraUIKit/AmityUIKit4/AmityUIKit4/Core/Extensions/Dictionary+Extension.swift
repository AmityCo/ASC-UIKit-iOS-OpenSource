//
//  Dictionary+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/24/23.
//

import Foundation

extension Dictionary {
    func decode<T: Decodable>(_ to: T.Type) throws -> T {
        let jsonData = try JSONSerialization.data(withJSONObject: self, options: [])
        let model = try JSONDecoder().decode(to, from: jsonData)
        return model
    }
}


extension Dictionary where Key == String, Value: Any {
    subscript(keyPath keyPath: String) -> Any? {
        get {
            let keys = keyPath.components(separatedBy: ".")

            // Use reduce to traverse the dictionary hierarchy
            return keys.reduce(self) { (current, key) in
                if let nestedDict = current as? [String: Any] {
                    return nestedDict[key]
                } else {
                    return nil
                }
            }
        }
    }
}
