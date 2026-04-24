//
//  AdSeenEvent.swift
//  AmityUIKit4
//
//  Created by Nishan on 19/6/2567 BE.
//

import Foundation
import CoreData

@objc(AdSeenEvent)
final class AdSeenEvent: NSManagedObject, FetchableModel {
    
    @NSManaged var adId: String
    @NSManaged var lastSeen: Date?
        
    static func upsert(adId: String, lastSeen: Date?, in context: NSManagedObjectContext) {
        let model: AdSeenEvent
        if let existing = AdSeenEvent.fetch(pKey: "adId", pValue: adId, in: context) {
            model = existing
        } else {
            model = AdSeenEvent(context: context)
            model.adId = adId
        }
        model.lastSeen = lastSeen
    }
    
    static func object(in context: NSManagedObjectContext, forPrimaryKey pValue: String) -> AdSeenEvent? {
        return AdSeenEvent.fetch(pKey: "adId", pValue: pValue, in: context)
    }
}
