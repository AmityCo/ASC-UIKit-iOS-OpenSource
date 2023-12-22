//
//  StoryPermissionManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/20/23.
//

import Foundation
import AmitySDK

// TEMP: Refactor this class
public class StoryPermissionChecker {
    public static let shared = StoryPermissionChecker()
    
    var communityId: String?
    var hasPermission: Bool?
    
    private init() {}
    
    public func setCommunity(id: String) {
        self.communityId = id
    }
    
    public func checkUserHasManagePermission(completion: @escaping (Bool) -> Void) {
        guard let communityId else {
            assertionFailure("Set community before checking permission.")
            return
        }
        
        AmityUIKitManagerInternal.shared.client.hasPermission(.manageStoryCommunity, forCommunity: communityId) { [weak self] hasPermission in
            self?.hasPermission = hasPermission
            completion(hasPermission)
        }
    }
    
    public func checkUserHasManagePermission() -> Bool {
        guard let hasPermission else {
            assertionFailure("checkUserHasManagePermission should be called first.")
            return false
        }
        
        return hasPermission
    }
}
