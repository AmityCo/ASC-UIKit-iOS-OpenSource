//
//  FetchableModel.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 17/3/26.
//

import Foundation
import CoreData

extension NSManagedObject {
    /// Identifier which returns the NSManagedObject class name itself.
    static var identifier: String {
        return String(describing: self)
    }
    
    class func fetch(pKey: String, pValue: String, in context: NSManagedObjectContext) -> Self? {
        let request = NSFetchRequest<Self>(entityName: Self.identifier)
        request.predicate = NSPredicate(format: "\(pKey) == %@", pValue)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}

/// This protocol adds helper method to fetch CoreData models.
protocol FetchableModel where Self: NSManagedObject {
    
    // Default fetch request
    static func fetchRequest() -> NSFetchRequest<Self>
    
    // Single Fetch
    static func fetch(predicate: NSPredicate, in context: NSManagedObjectContext) -> Self?
    
    // List Fetch
    static func fetchAll(sortDescriptors: [NSSortDescriptor], in context: NSManagedObjectContext) -> [Self]?
    static func fetchAll(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor], in context: NSManagedObjectContext) -> [Self]?
}

extension FetchableModel {
    
    static func fetchRequest() -> NSFetchRequest<Self> {
        return NSFetchRequest<Self>(entityName: Self.identifier)
    }
    
    static func fetch(predicate: NSPredicate, in context: NSManagedObjectContext) -> Self? {
        let request: NSFetchRequest = NSFetchRequest<Self>.init(entityName: Self.identifier)
        request.predicate = predicate
        request.fetchLimit = 1
        
        do {
            let results =  try context.fetch(request)
            return results.first
        } catch let error {
            Log.warn("Error fetching \(Self.identifier) \(error.localizedDescription)")
            return nil
        }
    }
    
    static func fetchAll(sortDescriptors: [NSSortDescriptor] = [], in context: NSManagedObjectContext) -> [Self]? {
        let request: NSFetchRequest = NSFetchRequest<Self>.init(entityName: Self.identifier)
        request.sortDescriptors = sortDescriptors
        
        do {
            let results =  try context.fetch(request)
            return results
        } catch let error {
            Log.warn("Error fetching \(Self.identifier) \(error.localizedDescription)")
            return nil
        }
    }
    
    static func fetchAll(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor] = [], in context: NSManagedObjectContext) -> [Self]? {
        let request: NSFetchRequest = NSFetchRequest<Self>.init(entityName: Self.identifier)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        do {
            let results =  try context.fetch(request)
            return results
        } catch let error {
            Log.warn("Error fetching \(Self.identifier) \(error.localizedDescription)")
            return nil
        }
    }
}
