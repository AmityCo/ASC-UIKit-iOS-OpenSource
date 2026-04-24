//
//  AdAsset.swift
//  AmityUIKit4
//
//  Created by Nishan on 19/6/2567 BE.
//

import Foundation
import AmitySDK
import CoreData

@objc(AdAsset)
final class AdAsset: NSManagedObject, FetchableModel {
    
    @NSManaged var fileId: String // primaryKey
    @NSManaged var fileURL: String?
    @NSManaged var isDownloaded: Bool
    
    static func upsert(ad: AmityAd, in context: NSManagedObjectContext) {
        if let image1_1 = ad.image1_1 {
            let fileId = image1_1.fileId
            let fileURL = image1_1.fileURL
            
            self.upsertAdAsset(fileId: fileId, fileURL: fileURL, in: context)
        }

        if let image9_16 = ad.image9_16 {
            let fileId = image9_16.fileId
            let fileURL = image9_16.fileURL

            self.upsertAdAsset(fileId: fileId, fileURL: fileURL, in: context)
        }
    }
    
    private static func upsertAdAsset(fileId: String, fileURL: String, in context: NSManagedObjectContext) {
        let model: AdAsset
        if let existing = AdAsset.fetch(pKey: "fileId", pValue: fileId, in: context) {
            model = existing
        } else {
            model = AdAsset(context: context)
            model.fileId = fileId
        }
        
        model.fileURL = fileURL
    }
    
    static func object(in context: NSManagedObjectContext, forPrimaryKey pValue: String) -> AdAsset? {
        return AdAsset.fetch(pKey: "fileId", pValue: pValue, in: context)
    }
}
