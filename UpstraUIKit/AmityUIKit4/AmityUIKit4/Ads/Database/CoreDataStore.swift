//
//  RealmStore.swift
//  AmityUIKit4
//
//  Created by Nishan on 15/6/2567 BE.
//

import Foundation
import AmitySDK
import CoreData

class CoreDataStore {
    
    let database: CoreDataDatabase?
    
    init() {
        let dataDatabaseURL = CoreDataStore.generateModelStoreURL(apiKey: "uikit_store", modelType: "data")
        
        database = try? CoreDataDatabase(modelName: "DataStore", url: dataDatabaseURL)
    }
    
    // Helpers
    private static func generateModelStoreURL(apiKey: String, modelType: String) -> URL {
        do {
            let cacheDirectory = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let dbDirectory = cacheDirectory.appendingPathComponent("social.plus.\(apiKey)/\(modelType)", isDirectory: true)
            
            if !FileManager.default.fileExists(atPath: dbDirectory.path) {
                try FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
            return dbDirectory
        } catch let error {
            preconditionFailure("[AmitySDK] Error occurred while initializing database directory: \(error)")
        }
    }
}

class CoreDataDatabase {
    
    public let persistentContainer: NSPersistentContainer
    
    // Context attached to main thread.
    // Note: This context should not be used outside main thread.
    public var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // Context attached to background thread. New context is generated everytime linked with persistent coordinator.
    // Unless you explicitly need this, use `performInBackground` method instead.
    public func backgroundContext() -> NSManagedObjectContext {
        let ctx = persistentContainer.newBackgroundContext()
        ctx.automaticallyMergesChangesFromParent = true
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        ctx.name = "Background \(Int.random(in: 0...999))"
        return ctx
    }
    
    init(modelName: String, url: URL) throws {
        // Load CoreData momd model file from Bundle
        guard let modelURL = Bundle(for: CoreDataStore.self).url(forResource: modelName, withExtension: "momd"), let model = NSManagedObjectModel(contentsOf: modelURL) else {
            preconditionFailure("[AmitySDK] Failed to initialize coredata model: \(modelName)")
        }
        self.persistentContainer = NSPersistentContainer(name: modelName, managedObjectModel: model)
        
        // Create & load database at provided location
        let storeURL = url.appendingPathComponent("\(modelName).sqlite")
                
        // Handle migration
        if FileManager.default.fileExists(atPath: storeURL.path) {
            if shouldDeleteStore(at: storeURL, for: model) {
                Log.add("\(modelName) requires database migration: TRUE")

                // Precaution incase store is loaded. Technically we should never reach this state
                let coordinator = persistentContainer.persistentStoreCoordinator
                if coordinator.persistentStore(for: storeURL) != nil {
                    try? coordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType)
                }
                
                // Delete all files located at URL
                deleteStore(at: storeURL)
            }
        }
        
        loadStore(container: persistentContainer, storeURL: storeURL)
        
        Log.add("\(modelName) database initialized at \(storeURL)")
    }
    
    // Deletes all data present in this database
    func deleteAllData() {
        let context = persistentContainer.viewContext
        let entities = persistentContainer.managedObjectModel.entities
        
        for entity in entities {
            guard let entityName = entity.name else { continue }
                        
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: entityName))
            do {
                try context.execute(deleteRequest)
                
                // Reset context so that changes are propagated to other contexts.
                context.reset()
            } catch let error {
                Log.warn("Error occurred while deleting all records for \(entityName). \(error.localizedDescription)")
            }
        }
    }
    
    private func loadStore(container: NSPersistentContainer, storeURL: URL) {
        
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        // Disable automatic migration
        storeDescription.shouldMigrateStoreAutomatically = false
        storeDescription.shouldInferMappingModelAutomatically = false
        
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores { description, error in
            if let error {
                // If loading fails, delete the store.
                self.deleteStore(at: storeURL)
                
                Log.warn("Failed to load persistent stores at \(storeURL), Error: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.name = "MainContext"
        container.viewContext.transactionAuthor = "AmitySDK"
    }
    
    private func deleteStore(at url: URL) {
        let fileManager = FileManager.default
        
        // Delete the main database file
        try? fileManager.removeItem(at: url)
        
        // Delete associated files (WAL, SHM)
        let walURL = url.deletingPathExtension().appendingPathExtension("sqlite-wal")
        let shmURL = url.deletingPathExtension().appendingPathExtension("sqlite-shm")
        
        try? fileManager.removeItem(at: walURL)
        try? fileManager.removeItem(at: shmURL)
    }
    
    private func shouldDeleteStore(at url: URL, for model: NSManagedObjectModel) -> Bool {
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: url)
            return !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        } catch {
            // If we can't read metadata, assume incompatibility
            return true
        }
    }
}

extension NSManagedObjectContext {
    
    /// Executes block in context queue asynchronously. After block execution, it saves the context. If you do not want to save context, use `performAndWait` method directly.
    /// - Parameter block: Operation to be perform in this context.
    func write<T>(_ block: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            self.perform {
                let result = block()
                
                do {
                    if self.hasChanges {
                        try self.save()
                    }
                } catch let error {
                    #if DEBUG
                    fatalError("Error saving managed object context: \(error)")
                    #else
                    Log.warn("Error while saving managed object context \(error)")
                    #endif
                }
                
                continuation.resume(returning: result)
            }
        }
    }
    
    // async await support for perform method < iOS 15. Once our min target is
    // upgraded to 15, remove this method & use perform directly.
    func asyncPerform<T>(_ block: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            self.perform {
                let result = block()
                
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Executes block in context queue asynchronously. After block execution, it saves the context. If you do not want to save context, use `perform` method directly.
    /// - Parameter block: Operation to be perform in this context.
    func writeAsync(_ block: @escaping () -> Void) {
        self.perform {
            block()
            
            if self.hasChanges {
                do {
                    try self.save()
                } catch {
                    #if DEBUG
                    fatalError("Error saving managed object context: \(error)")
                    #else
                    Log.warn("Error while saving managed object context \(error)")
                    #endif
                }
            }
        }
    }
    
    func deleteAll(objects: [NSManagedObject]) {
        for object in objects {
            self.delete(object)
        }
    }
}

