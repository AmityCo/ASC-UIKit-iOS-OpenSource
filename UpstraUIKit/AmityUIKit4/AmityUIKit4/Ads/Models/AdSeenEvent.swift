//
//  AdSeenEvent.swift
//  AmityUIKit4
//
//  Created by Nishan on 19/6/2567 BE.
//

import Foundation
import RealmSwift

class AdSeenEvent: UIKitRealmModel {
    
    @Persisted(primaryKey: true) var adId: String
    @Persisted var lastSeen: Date?
    
    static func upsert(adId: String, lastSeen: Date?, in store: Realm) {
        var object = [String: Any]()
        object["adId"] = adId
        
        if let lastSeen {
            object["lastSeen"] = lastSeen
        }
        
        store.create(AdSeenEvent.self, value: object, update: .all)
    }
}
