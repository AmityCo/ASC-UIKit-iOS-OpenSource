//
//  AmityUIKitBehaviour.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/22/23.
//

import Foundation

open class AmityUIKitBehaviour {
    // MARK: - Story
    public var createStoryPageBehaviour: AmityCreateStoryPageBehaviour?
    public var draftStoryPageBehaviour: AmityDraftStoryPageBehaviour?
    public var storyTabComponentBehaviour: AmityStoryTabComponentBehaviour?
    public var viewStoryPageBehaviour: AmityViewStoryPageBehaviour?
    public var targetSelectionPageBehaviour: AmityTargetSelectionPageBehaviour?
    
    // MARK: - Social
    public var globalFeedComponentBehavior: AmityGlobalFeedComponentBehavior?
    public var postContentComponentBehavior: AmityPostContentComponentBehavior?
}
