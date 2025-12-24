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
    let event: AmityEvent?
    
    let pollManager = PollManager()
    let postManager = PostManager()
    let communityManager = CommunityManager()
    
    @Published var pollTarget = AmityLocalizedStringSet.Social.pollTargetMyTimeline.localizedString
    @Published var isCreatingPollPost = false
    @Published var textOptions: [PollOption] = [PollOption(index: 0), PollOption(index: 1)]
    @Published var imageOptions: [PollImageOption] = [PollImageOption(), PollImageOption()]
    
    let fileRepository = AmityFileRepository(client: AmityUIKitManagerInternal.shared.client)
    
    init(targetId: String?, targetType: AmityPostTargetType, event: AmityEvent?) {
        self.targetId = targetId
        self.targetType = targetType
        self.event = event
        self.setupTarget(targetType: targetType, targetId: targetId)
    }
    
    func setupTarget(targetType: AmityPostTargetType, targetId: String?) {
        switch targetType {
        case .community:
            if let event {
                self.pollTarget = event.title
                return
            }
            
            if let targetId, let community = communityManager.getCommunity(withId: targetId).snapshot {
                self.pollTarget = community.displayName
            }
        default:
            break
        }
    }
    
    @MainActor
    func createImagePollPost(title: String = "", question: String, answers: [(image: AmityImageData, text: String?)], isMultipleSelection: Bool, closedIn: Int, metadata: [String: Any]?, mentionees: AmitySDK.AmityMentioneesBuilder?, hashtags: AmitySDK.AmityHashtagBuilder?) async throws -> AmityPost {
        
        let sanitizedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        isCreatingPollPost = true
        // Create Poll
        let pollId = try await pollManager.createImagePoll(question: sanitizedQuestion, answers: answers, isMultipleSelection: isMultipleSelection, closedIn: closedIn)
        
        // Create Post
        let pollPostBuilder = AmityPollPostBuilder()
        pollPostBuilder.setText(sanitizedQuestion)
        pollPostBuilder.setTitle(sanitizedTitle)
        pollPostBuilder.setPollId(pollId)
        
        let post = try await postManager.postRepository.createPollPost(pollPostBuilder, targetId: targetId, targetType: targetType, metadata: metadata, mentionees: mentionees, hashtags: hashtags)
        
        /// Send didPostCreated event to mod global feed listing
        /// This event is observed in PostFeedViewModel
        NotificationCenter.default.post(name: .didPostCreated, object: post)
        
        return post
    }
    
    @MainActor
    func createTextPollPost(title: String = "", question: String, answers: [String], isMultipleSelection: Bool, closedIn: Int, metadata: [String: Any]?, mentionees: AmitySDK.AmityMentioneesBuilder?, hashtags: AmitySDK.AmityHashtagBuilder?) async throws -> AmityPost {
        
        let sanitizedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        isCreatingPollPost = true
        // Create Poll
        let pollId = try await pollManager.createTextPoll(question: sanitizedQuestion, answers: answers, isMultipleSelection: isMultipleSelection, closedIn: closedIn)
        
        // Create Post
        let pollPostBuilder = AmityPollPostBuilder()
        pollPostBuilder.setTitle(sanitizedTitle)
        pollPostBuilder.setText(sanitizedQuestion)
        pollPostBuilder.setPollId(pollId)
        
        let post = try await postManager.postRepository.createPollPost(pollPostBuilder, targetId: targetId, targetType: targetType, metadata: metadata, mentionees: mentionees, hashtags: hashtags)
        
        /// Send didPostCreated event to mod global feed listing
        /// This event is observed in PostFeedViewModel
        NotificationCenter.default.post(name: .didPostCreated, object: post)
        
        return post
    }
    
    func removeTextOption(at index: Int) {
        textOptions.remove(at: index)
        
        // Update options with correct index
        var curIndex = 0
        let updatedOptions = textOptions.map {
            let newOption = PollOption(text: $0.text, index: curIndex)
            curIndex += 1
            return newOption
        }
        
        self.textOptions = updatedOptions
    }
    
    func isAnyPollOptionEdited() -> Bool {
        let editedTextOptions = textOptions.filter { !$0.text.isEmpty }
        let editedImageOptions = imageOptions.filter { $0.uploadState != .empty || !$0.text.isEmpty }
        
        return !editedTextOptions.isEmpty || !editedImageOptions.isEmpty
    }
}

// Image Poll Options
extension PollPostComposerViewModel {
    
    func addImageOption() {
        imageOptions.append(PollImageOption())
    }
    
    func removeImageOption(at index: Int) {
        imageOptions.remove(at: index)
    }
    
    func updateText(for option: PollImageOption, text: String) {
        if let index = imageOptions.firstIndex(where: { $0.id == option.id }) {
            imageOptions[index].text = text
        }
    }
    
    func updateImage(for option: PollImageOption, image: UIImage?) {
        if let index = imageOptions.firstIndex(where: { $0.id == option.id }) {
            imageOptions[index].image = image
        }
    }
    
    func updateUploadState(for option: PollImageOption, state: PollImageOptionState, imageData: AmityImageData?) {
        if let index = imageOptions.firstIndex(where: { $0.id == option.id }) {
            imageOptions[index].uploadState = state
            imageOptions[index].imageData = imageData
        }
    }
    
    func updateAltText(for option: PollImageOption, text: String) {
        if let index = imageOptions.firstIndex(where: { $0.id == option.id }) {
            imageOptions[index].altText = text
        }
    }
    
    func updateUploadState(for option: PollImageOption, state: PollImageOptionState, fileId: String?) {
        if let index = imageOptions.firstIndex(where: { $0.id == option.id }) {
            imageOptions[index].uploadState = state
        }
    }
}
