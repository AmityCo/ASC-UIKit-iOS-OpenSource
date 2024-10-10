//
//  AmityReactionListViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan on 8/5/2567 BE.
//

import Foundation
import AmitySDK
import Combine
import OSLog

class AmityReactionListViewModel: ObservableObject {
    
    // Query state when reaction user list is queried for the first time.
    @Published var reactionInfo: [String: Int] = [:]
    var reactionTotalCount: Int = 0
    
    private let chatManager = ChatManager()
    private let commentManager = CommentManager()

    let referenceId: String
    let referenceType: AmityReactionReferenceType
    var parentObjectToken: AmityNotificationToken?
    
    @Published var emptyStateConfiguration = AmityEmptyStateView.Configuration(image: AmityIcon.Chat.greyRetryIcon.rawValue, title: AmityLocalizedStringSet.Reaction.unableToLoadTitle.localizedString, subtitle: nil, tapAction: nil)
    
    init(referenceId: String, referenceType: AmityReactionReferenceType) {
        self.referenceId = referenceId
        self.referenceType = referenceType
        self.observeReactionChanges()
    }
    
    func resolveReactionInfo(completion: (_ reactions: [String: Int], _ totalCount: Int) -> Void) {
        switch referenceType {
        case .message:
            if let message = chatManager.getMessage(messageId: referenceId).snapshot {
                completion(message.reactions as? [String: Int] ?? [:], message.reactionCount)
            }
        case .comment:
            if let comment = commentManager.getComment(commentId: referenceId).snapshot {
                completion(comment.reactions as? [String: Int] ?? [:], comment.reactionsCount)
            }
        default:
            break
        }
    }
    
    func observeReactionChanges() {
        // Observe if observation is not yet started.
        guard parentObjectToken == nil else { return }
        
        switch referenceType {
        case .message:
            // Observe for changes in reactions
            parentObjectToken = chatManager.getMessage(messageId: referenceId).observe({ [weak self] liveObject, error in
                guard let self, liveObject.dataStatus == .fresh, let message = liveObject.snapshot else { return }
                handleReactionChanges(reactionCount: message.reactionCount, reactionInfo: message.reactions as? [String: Int] ?? [:])
            })
            
        case .comment:
            parentObjectToken = commentManager.getComment(commentId: referenceId).observe({ [weak self] liveObject, error in
                guard let self, liveObject.dataStatus == .fresh, let comment = liveObject.snapshot else { return }
                handleReactionChanges(reactionCount: comment.reactionsCount, reactionInfo: comment.reactions as? [String: Int] ?? [:])
            })
        default:
            break
        }
    }
        
    deinit {
        parentObjectToken?.invalidate()
        parentObjectToken = nil
    }
    
    func handleReactionChanges(reactionCount: Int, reactionInfo: [String: Int]) {
        // Publish reaction changes per tabs
        self.reactionTotalCount = reactionCount
        self.reactionInfo = reactionInfo
    }
}
