//
//  Array+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/15/24.
//

import Foundation

extension Array where Element: Equatable {
    // use this if you need the same order as orginal array
    // Array(Set(orginalArray)) do not guarantee the order
    // time complexity will be n2
    func removeDuplicates() -> [Element] {
        var result: [Element] = []
        
        for element in self {
            if !result.contains(element) {
                result.append(element)
            }
        }
        
        return result
    }
}

extension Collection {
    func element(at index: Index) -> Element? {
        guard indices.contains(index) else {
            return nil
        }
        return self[index]
    }
}
