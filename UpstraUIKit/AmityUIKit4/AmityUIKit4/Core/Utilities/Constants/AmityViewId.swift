//
//  AmityViewId.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/21/23.
//

import Foundation

public enum PageId: String {
    // MARK: - Story
    case storyCreationPage = "create_story_page"
    case storyPage = "story_page"
    case cameraPage = "camera_page"
    case storyTargetSelectionPage = "select_story_target_page"
    
    // MARK: - Chat
    case liveChatPage = "live_chat"
    
    // MARK: - Social
    case socialHomePage = "social_home_page"
    case postDetailPage = "post_detail_page"
    case socialGlobalSearchPage = "social_global_search_page"
    case postComposerPage = "post_composer_page"
    case postTargetSelectionPage = "select_post_target_page"
    case myCommunitiesSearchPage = "my_communities_search_page"
    case pollTargetSelectionPage = "select_poll_target_page"
    case liveStreamTargetSelectionPage = "livestream_post_target_selection_page"
    case liveStreamTerminatedPage = "livestream_terminated_page"
    
    case communityProfilePage = "community_profile_page"
    
    case communitySetupPage = "community_setup_page"
    case communityAddCategoryPage = "community_add_category_page"
    case communityAddUserPage = "community_add_user_page"
    case communitySettingPage = "community_setting_page"
    case communityMembershipPage = "community_membership_page"
    case communityNotificationSettingPage = "community_notification_page"
    case communityPostPermissionPage = "community_post_permission_page"
    case communityStorySettingPage = "community_story_setting_page"
    case communityPostsNotificationSettingPage = "community_posts_notification_page"
    case communityCommentsNotificationSettingPage = "community_comments_notification_page"
    case communityStoriesNotificationSettingPage = "community_stories_notification_page"
    case communityPendingPostPage = "pending_posts_page"
    
    case livestreamPlayerPage = "livestream_player_page"
    case createLivestreamPage = "create_livestream_page"

    case userProfilePage = "user_profile_page"
    case editUserProfilePage = "edit_user_profile_page"
    case userRelationshipPage = "user_relationship_page"
    case blockedUsersPage = "blocked_users_page"
    case pendingFollowRequestPage = "user_pending_follow_request_page"
    
    case communitiesByCategoryPage = "communities_by_category_page"
    case allCategories = "all_categories_page"
    
    case pollPostPage = "poll_post_composer_page"
}

public enum ComponentId: String {
    // MARK: - Story
    case storyTabComponent = "story_tab_component"
    case hyperLinkConfigComponent = "hyper_link_config_component"
    case commentTrayComponent = "comment_tray_component"
    
    // MARK: - Chat
    case messageComposer = "message_composer"
    case messageList = "message_list"
    case liveChatHeader = "live_chat_header"
    case reactionList = "reaction_list"
    
    // MARK: - Social
    case socialHomePageTopNavigationComponent = "top_navigation"
    case emptyNewsFeedComponent = "empty_newsfeed"
    case newsFeedComponent = "newsfeed_component"
    case postContentComponent = "post_content"
    case globalFeedComponent = "global_feed_component"
    case myCommunitiesComponent = "my_communities"
    case topSearchBarComponent = "top_search_bar"
    case communitySearchResultComponent = "community_search_result"
    case userSearchResultComponent = "user_search_result"
    case createPostMenu = "create_post_menu"
    case communityHeader = "community_header"
    case communityProfileTab = "community_profile_tab"
    case communityFeed = "community_feed"
    case communityPin = "community_pin"
    case mediaAttachment = "media_attachment"
    case detailedMediaAttachment = "detailed_media_attachment"
    case communityImageFeed = "community_image_feed"
    case pendingPostContentComponent = "pending_post_content"

    case recommendedCommunities = "recommended_communities"
    case trendingCommunities = "trending_communities"
    case communityCategories = "community_categories"
    
    case userProfileHeader = "user_profile_header"
    case userFeed = "user_feed"
    case userImageFeed = "user_image_feed"
    case userVideoFeed = "user_video_feed"
}

public enum ElementId: String {
    // MARK: - Story
    // Story Tab Component
    case storyRingElement = "story_ring"
    case createNewStoryButtonElement = "create_new_story_button"
    
    // View Story Page
    case progressBarElement = "progress_bar"
    case closeButtonElement = "close_button"
    case overflowMenuElement = "overflow_menu"
    case impressionIconElement = "story_impression_button"
    case storyCommentButtonElement = "story_comment_button"
    case storyReactionButtonElement = "story_reaction_button"
    case muteUnmuteButtonElement = "speaker_button"
    
    // Draft Story Page
    case backButtonElement = "back_button"
    case aspectRatioButtonElement = "aspect_ratio_button"
    case shareStoryButtonElement = "share_story_button"
    case hyperLinkButtonElement = "story_hyperlink_button"
    case hyperLinkElement = "hyper_link"
    
    // Hyper Link Component
    case doneButtonElement = "done_button"
    case cancelButtonElement = "cancel_button"
    
    case sendButton = "send_button"
    case textField = "text_field"
    case theme = "theme"
    
    case senderMessageBubble = "sender_message_bubble"
    case receiverMessageBubble = "receiver_message_bubble"
    
    // MARK: - Chat
    // Chat Elements
    case memberCount = "member_count"
    case connectivity = "conectivity"
    case avatar = "avatar"
    
    // Reaction
    case messageReactionPicker = "message_reaction_picker"
    case messageQuickReaction = "message_quick_reaction"
    
    // MARK: - Social
    case headerLabel = "header_label"
    case globalSearchButton = "global_search_button"
    case postCreationButton = "post_creation_button"
    case newsFeedButton = "newsfeed_button"
    case exploreButton = "explore_button"
    case myCommunitiesButton = "my_communities_button"
    
    // EmptyNewsFeed
    case illustration = "illustration"
    case title = "title"
    case description = "description"
    case exploreCommunittiesButton = "explore_communitties_button"
    case createCommunityButton = "create_community_button"
    
    // MyCommunities
    case communityAvatar = "community_avatar"
    case communityDisplayName = "community_display_name"
    case communityPrivateBadge = "community_private_badge"
    case communityOfficialBadge = "community_official_badge"
    case communityCategoryName = "community_category_name"
    case communityMembersCount = "community_members_count"
    
    // PostDetail
    case menuButton = "menu_button"
    
    // PostContent
    case moderatorBadge = "moderator_badge"
    case timestamp = "timestamp"
    case postContent = "post_content_view_count"
    case reactionButton = "reaction_button"
    case commentButton = "comment_button"
    case shareButton = "share_button"
    case nonMemberSection = "non_member_section"
    case announcementBadge = "announcement_badge"
    case pinBadge = "pin_badge"
    
    // TopSearchBar
    case searchIcon = "search_icon"
    case clearButton = "clear_button"
    
    // CommunityProfileHeader
    case communityName = "community_name"
    case communityCover = "community_cover"
    case communityVerifyBadge = "community_verify_badge"
    case communityCategory = "community_category"
    case communityDescription = "community_description"
    case communityInfo = "community_info"
    case communityJoinButton = "community_join_button"
    case communityPendingPost = "community_pending_post"
    
    // CommunityProfileTab
    case communityFeedTabButton = "community_feed_tab_button"
    case communityPinTabButton = "community_pin_tab_button"
    
    // CreatePostMenu
    case createPostButton = "create_post_button"
    case createStoryButton = "create_story_button"
    case createPollButton = "create_poll_button"
    case createLivestreamButton = "create_livestream_button"
    
    // PostTargetSelectionPage
    case myTimelineAvatar = "my_timeline_avatar"
    case myTimelineText = "my_timeline_text"
    
    // PostComposerPage
    case createNewPostButton = "create_new_post_button"
    case editPostButton = "edit_post_button"
    case editPostTitle = "edit_post_title"
    
    // MediaAttachment
    case cameraButton = "camera_button"
    case imageButton = "image_button"
    case videoButton = "video_button"
    case fileButton = "file_button"
    
    // Community Setup Page
    case communityEditTitle = "community_edit_title"
    case communityNameTitle = "community_name_title"
    case communityAboutTitle = "community_about_title"
    case communityCategoryTitle = "community_category_title"
    case communityPrivacyTitle = "community_privacy_title"
    case communityPrivacyPrivateIcon = "community_privacy_private_icon"
    case communityPrivacyPrivateTitle = "community_privacy_private_title"
    case communityPrivacyPrivateDescription = "community_privacy_private_description"
    case communityPrivacyPublicIcon = "community_privacy_public_icon"
    case communityPrivacyPublicTitle = "community_privacy_public_title"
    case communityPrivacyPublicDescription = "community_privacy_public_description"
    case communityAddMemberTitle = "community_add_member_title"
    case communityAddMemberButton = "community_add_member_button"
    case communityCreateButton = "community_create_button"
    case communityEditButton = "community_edit_button"
    
    // Pending Posts Page
    case postAcceptButton = "post_accept_button"
    case postDeclineButton = "post_decline_button"
    
    // Community Setting Page
    case editProfile = "edit_profile"
    case members = "members"
    case notifications = "notifications"
    case postPermission = "post_permission"
    case storySetting = "story_setting"
    case leaveCommunity = "leave_community"
    case closeCommunity = "close_community"
    case closeCommunityDescription = "close_community_description"
    
    // UserProfilePage
    case userFeedTabButton = "user_feed_tab_button"
    case userImageFeedTabButton = "user_image_feed_tab_button"
    case userVideoFeedTabButton = "user_video_feed_tab_button"
    
    // UserProfileHeader
    case followUserButton = "follow_user_button"
    case followingUserButton = "following_user_button"
    case pendingUserButton = "pending_user_button"
    case unblockUserButton = "unblock_user_button"
    case userAvatar = "user_avatar"
    case userName = "user_name"
    case userDescription = "user_description"
    case userFollowing = "user_following"
    case userFollower = "user_follower"
    
    // User Feed, Image Feed, Video Feed
    case emptyUserFeed = "empty_user_feed"
    case privateUserFeed = "private_user_feed"
    case privateUserFeedInfo = "private_user_feed_info"
    case blockedUserFeed = "blocked_user_feed"
    case blockedUserFeedInfo = "blocked_user_feed_info"
    case emptyUserImageFeed = "empty_user_image_feed"
    case privateUserImageFeed = "private_user_image_feed"
    case privateUserImageFeedInfo = "private_user_image_feed_info"
    case blockedUserImageFeed = "blocked_user_image_feed"
    case blockedUserImageFeedInfo = "blocked_user_image_feed_info"
    case emptyUserVideoFeed = "empty_user_video_feed"
    case privateUserVideoFeed = "private_user_video_feed"
    case privateUserVideoFeedInfo = "private_user_video_feed_info"
    case blockedUserVideoFeed = "blocked_user_video_feed"
    case blockedUserVideoFeedInfo = "blocked_user_video_feed_info"
    // Edit User Profile
    case userDisplayNameTitle = "user_display_name_title"
    case userAboutTitle = "user_about_title"
    case updateUserProfileButton = "update_user_profile_button"
}
