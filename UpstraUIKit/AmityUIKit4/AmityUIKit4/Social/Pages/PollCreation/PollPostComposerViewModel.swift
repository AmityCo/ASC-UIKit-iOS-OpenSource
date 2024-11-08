//
//  PollPostComposerViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 17/10/2567 BE.
//

import SwiftUI
import AmitySDK

class PollPostComposerViewModel: ObservableObject {
    
    let targetId: String?
    let targetType: AmityPostTargetType
    
    let pollManager = PollManager()
    let postManager = PostManager()
    let communityManager = CommunityManager()
    
    @Published var pollTarget = AmityLocalizedStringSet.Social.pollTargetMyTimeline.localizedString
    @Published var isCreatingPollPost = false
    @Published var options: [PollOption] = [PollOption(index: 0), PollOption(index: 1)]
    
    init(targetId: String?, targetType: AmityPostTargetType) {
        self.targetId = targetId
        self.targetType = targetType
        self.setupTarget(targetType: targetType, targetId: targetId)
    }
    
    func setupTarget(targetType: AmityPostTargetType, targetId: String?) {
        switch targetType {
        case .community:
            if let targetId, let community = communityManager.getCommunity(withId: targetId).snapshot {
                self.pollTarget = community.displayName
            }
        default:
            break
        }
    }
    
    @MainActor
    func createPollPost(question: String, answers: [String], isMultipleSelection: Bool, closedIn: Int, metadata: [String: Any]?, mentionees: AmitySDK.AmityMentioneesBuilder?) async throws {
        
        let sanitizedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        
        isCreatingPollPost = true
        // Create Poll
        let pollId = try await pollManager.createPoll(question: sanitizedQuestion, answers: answers, isMultipleSelection: isMultipleSelection, closedIn: closedIn)
        
        // Create Post
        let pollPostBuilder = AmityPollPostBuilder()
        pollPostBuilder.setText(sanitizedQuestion)
        pollPostBuilder.setPollId(pollId)
        
        let post = try await postManager.createPost(pollPostBuilder, targetId: targetId, targetType: targetType, metadata: metadata, mentionees: mentionees)
        
        /// Send didPostCreated event to mod global feed listing
        /// This event is observed in PostFeedViewModel
        NotificationCenter.default.post(name: .didPostCreated, object: post)
    }
    
    func removePollOption(at index: Int) {
        options.remove(at: index)
        
        // Update options with correct index
        var curIndex = 0
        let updatedOptions = options.map {
            let newOption = PollOption(text: $0.text, index: curIndex)
            curIndex += 1
            return newOption
        }
        
        self.options = updatedOptions
    }
}
