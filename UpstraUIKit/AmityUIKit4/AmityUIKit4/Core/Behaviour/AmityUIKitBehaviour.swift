//
//  AmityUIKitBehaviour.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/22/23.
//

import Foundation
import UIKit

open class AmityUIKitBehaviour {
    // MARK: - Story
    public var createStoryPageBehaviour: AmityCreateStoryPageBehaviour?
    public var draftStoryPageBehaviour: AmityDraftStoryPageBehaviour?
    public var storyTabComponentBehaviour: AmityStoryTabComponentBehaviour?
    public var viewStoryPageBehaviour: AmityViewStoryPageBehaviour?
    public var storyTargetSelectionPageBehaviour: AmityStoryTargetSelectionPageBehaviour?
    public var commentTrayComponentBehavior: AmityCommentTrayComponentBehavior?
    
    // MARK: - Social
    public var socialHomePageBehavior: AmitySocialHomePageBehavior?
    public var myCommunitiesComponentBehavior: AmityMyCommunitiesComponentBehavior?
    public var newsFeedComponentBehavior: AmityNewsFeedComponentBehavior?
    public var globalFeedComponentBehavior: AmityGlobalFeedComponentBehavior?
    public var postContentComponentBehavior: AmityPostContentComponentBehavior?
    public var createPostMenuComponentBehavior: AmityCreatePostMenuComponentBehavior?
    public var postTargetSelectionPageBehavior: AmityPostTargetSelectionPageBehavior?
    public var pollTargetSelectionPageBehavior: AmityPollTargetSelectionPageBehavior?
    public var liveStreamPostTargetSelectionPageBehavior: AmityLivestreamPostTargetSelectionPageBehavior?
    public var postDetailPageBehavior: AmityPostDetailPageBehavior?
    public var socialGlobalSearchPageBehavior: AmitySocialGlobalSearchPageBehavior?
    public var socialHomeTopNavigationComponentBehavior: AmitySocialHomeTopNavigationComponentBehavior?
    public var myCommunitiesSearchPageBehavior: AmityMyCommunitiesSearchPageBehavior?
    public var communitySearchResultComponentBehavior: AmityCommunitySearchResultComponentBehavior?
    public var userSearchResultComponentBehavior: AmityUserSearchResultComponentBehavior?
    public var postComposerPageBehavior: AmityPostComposerPageBehavior?
    public var communityProfilePageBehavior: AmityCommunityProfilePageBehavior?
    public var communitySetupPageBehavior: AmityCommunitySetupPageBehavior?
    public var communityMembershipPageBehavior: AmityCommunityMembershipPageBehavior?
    public var communitySettingPageBehavior: AmityCommunitySettingPageBehavior?
    public var communityNotificationSettingPageBehavior: AmityCommunityNotificationSettingPageBehavior?
    public var userProfilePageBehavior: AmityUserProfilePageBehavior?
    public var userProfileHeaderComponentBehavior: AmityUserProfileHeaderComponentBehavior?
    public var userRelationshipPageBehavior: AmityUserRelationshipPageBehavior?
    public var userPendingFollowRequestsPageBehavior: AmityUserPendingFollowRequestsPageBehavior?
    public var blockedUsersPageBehavior: AmityBlockedUsersPageBehavior?
    public var pendingPostContentComponentBehavior: AmityPendingPostContentComponentBehavior?    
    public var livestreamBehavior: AmityLivestreamBehavior?
    
    // We want swipe to back gesture behavior available by default.
    public var swipeToBackGestureBehaviour: AmitySwipeToBackGestureBehavior? = AmitySwipeToBackGestureBehavior()    
}

open class AmitySwipeToBackGestureBehavior {
    
    public init() {}
    
    open func gestureRecognizerShouldBegin(navigationController: UINavigationController, _ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == navigationController.interactivePopGestureRecognizer else { return true }
        
        return navigationController.viewControllers.count > 1
    }
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
}
