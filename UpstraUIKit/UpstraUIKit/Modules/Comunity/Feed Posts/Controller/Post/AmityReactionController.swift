//
//  AmityReactionController.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/13/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

public enum AmityReactionType: String {
    case like
}

protocol AmityReactionControllerProtocol {
    func addReaction(withReaction reaction: AmityReactionType, referenceId: String, referenceType: AmityReactionReferenceType, completion: AmityRequestCompletion?)
    func removeReaction(withReaction reaction: AmityReactionType, referenceId: String, referenceType: AmityReactionReferenceType, completion: AmityRequestCompletion?)
}

final class AmityReactionController: AmityReactionControllerProtocol {
    
    private let repository = AmityReactionRepository(client: AmityUIKitManagerInternal.shared.client)

    func addReaction(withReaction reaction: AmityReactionType, referenceId: String, referenceType: AmityReactionReferenceType, completion: AmityRequestCompletion?) {
        Task { @MainActor in
            do {
                let result = try await repository.addReaction(reaction.rawValue, referenceId: referenceId, referenceType: referenceType)
                completion?(result, nil)
            } catch let error {
                completion?(false, error)
            }
        }
    }
    
    func removeReaction(withReaction reaction: AmityReactionType, referenceId: String, referenceType: AmityReactionReferenceType, completion: AmityRequestCompletion?) {
        Task { @MainActor in
            do {
                let result = try await repository.removeReaction(reaction.rawValue, referenceId: referenceId, referenceType: referenceType)
                completion?(result, nil)
            } catch let error {
                completion?(false, error)
            }
        }
    }
}
