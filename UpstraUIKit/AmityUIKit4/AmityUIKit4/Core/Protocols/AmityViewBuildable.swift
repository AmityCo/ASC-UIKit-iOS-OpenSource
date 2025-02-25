//
//  AmityViewBuildable.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 3/13/24.
//

import Foundation

protocol AmityViewBuildable {}

extension AmityViewBuildable {
    func mutating<T>(keyPath: WritableKeyPath<Self, T>, value: T) -> Self {
        var newSelf = self
        newSelf[keyPath: keyPath] = value
        return newSelf
    }
}
