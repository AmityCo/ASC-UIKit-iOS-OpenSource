//
//  UIKitRealmModel.swift
//  AmityUIKit4
//
//  Created by Nishan on 19/6/2567 BE.
//

import Foundation
import RealmSwift

class UIKitRealmModel: Object {
    
    override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
}
