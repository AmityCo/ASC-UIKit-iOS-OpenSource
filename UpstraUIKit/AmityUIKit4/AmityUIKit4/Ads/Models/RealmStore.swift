//
//  RealmStore.swift
//  AmityUIKit4
//
//  Created by Nishan on 15/6/2567 BE.
//

import Foundation
import AmitySDK
import RealmSwift

/// Managed communication with realm
class RealmStore {
    
    static let shared = RealmStore()
    
    let database: Realm?
    
    private init() {
        let baseDirectory = Self.getDatabaseDirectory()
        let url = baseDirectory.appendingPathComponent("uikit_store").appendingPathExtension("realm")
        
        var realmConfig = Realm.Configuration.defaultConfiguration
        realmConfig.deleteRealmIfMigrationNeeded = true
        realmConfig.fileURL = url
        realmConfig.objectTypes = Self.getManagedRealmModels()
        
        self.database = try? Realm(configuration: realmConfig)
    }
    
    func write(_ action: @escaping () -> Void) {
        guard let database else { return }
        
        if database.isInWriteTransaction {
            action()
        } else {
            database.writeAsync {
                action()
            }
        }
    }
    
    func clear() {
        write { [weak self] in
            self?.database?.deleteAll()
        }
    }
}

extension RealmStore {
    
    class func getDatabaseDirectory() -> URL {
        do {
            let cacheDirectory = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let dbDirectory = cacheDirectory.appendingPathComponent("com.amity.uikit.realm", isDirectory: true)
            
            if !FileManager.default.fileExists(atPath: dbDirectory.path) {
                try FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
            return dbDirectory
        } catch let error {
            preconditionFailure("[AmitySDK] Error occurred while initializing database directory: \(error)")
        }
    }
    
    class func setUpRealmConfig(url: URL, objectClasses: [ObjectBase.Type]) -> Realm.Configuration {
        var realmConfig = Realm.Configuration.defaultConfiguration
        realmConfig.deleteRealmIfMigrationNeeded = true
        realmConfig.fileURL = url
        realmConfig.objectTypes = objectClasses
        return realmConfig
    }
    
    class func getManagedRealmModels() -> [ObjectBase.Type] {
        return [
            AdAsset.self,
            AdSeenEvent.self
        ]
    }
}

extension Realm {
    
    /// Asynchronously performs operations within realm write transaction.
    func performAsync(_ action: @escaping () -> Void) {
        if self.isInWriteTransaction {
            action()
        } else {
            self.writeAsync {
                action()
            }
        }
    }
    
    func perform(_ action: @escaping () -> Void) {
        if self.isInWriteTransaction {
            action()
        } else {
            try? self.write {
                action()
            }
        }
    }
}
