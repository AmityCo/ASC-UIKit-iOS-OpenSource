//
//  AdAsset.swift
//  AmityUIKit4
//
//  Created by Nishan on 19/6/2567 BE.
//

import Foundation
import RealmSwift
import AmitySDK

class AdAsset: UIKitRealmModel {
    @Persisted(primaryKey: true) var fileId: String
    @Persisted var fileURL: String?
    @Persisted var isDownloaded: Bool = false
    
    static func upsert(ad: AmityAd, in store: Realm) {
        if let image1_1 = ad.image1_1 {
            let fileId = image1_1.fileId
            let fileURL = image1_1.fileURL
            
            let object = ["fileId": fileId, "fileURL": fileURL]
            store.create(AdAsset.self, value: object, update: .all)
        }
        
        if let image9_16 = ad.image9_16 {
            let fileId = image9_16.fileId
            let fileURL = image9_16.fileURL
            
            let object = ["fileId": fileId, "fileURL": fileURL]
            store.create(AdAsset.self, value: object, update: .all)
        }
    }
}
