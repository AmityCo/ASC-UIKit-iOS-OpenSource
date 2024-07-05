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
    case targetSelectionPage = "select_target_page"
    
    // MARK: - Chat
    case liveChatPage = "live_chat"
    
    // MARK: - Social
    case socialHomePage = "social_home_page"
    case postDetailPage = "post_detail_page"
    case socialGlobalSearchPage = "social_global_search_page"
    case createPostPage = "create_post_page"
    case postTargetSelectionPage = "select_post_target_page"
    case myCommunitiesSearchPage = "my_communities_search_page"
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
    
    // TopSearchBar
    case searchIcon = "search_icon"
    case clearButton = "clear_button"
}
