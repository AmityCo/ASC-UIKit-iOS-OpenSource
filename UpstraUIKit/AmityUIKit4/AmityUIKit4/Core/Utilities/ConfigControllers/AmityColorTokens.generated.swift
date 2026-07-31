//
//  AmityColorTokens.generated.swift
//  AmityUIKit4
//
//  Auto-generated from AmityUIKitDesignTokens.json by scripts/generate_color_tokens.py.
//  Do not edit manually — re-run the script after updating the design tokens JSON.
//

import UIKit

/// Alias color tokens from the design system. Each alias resolves to a theme
/// palette color (`AmityThemeColor`) or a fixed color (`AmityFixedColor`).
enum AmityColorAlias: String, CaseIterable {
    /// {theme.background_color}
    case backgroundBlackDefault = "Background/Black/Default"
    /// {theme.background_color}
    case backgroundStandardBlackDefault = "Background/Standard/Black/Default"
    /// {theme.background_shade1_color}
    case backgroundStandardBlackSubdue = "Background/Standard/Black/Subdue"
    /// {theme.background_color}
    case backgroundStandardWhiteDefault = "Background/Standard/White/Default"
    /// {theme.transparent_black_shade1_color}
    case backgroundTransparentBlack200 = "Background/Transparent/Black/200"
    /// {theme.transparent_black_shade2_color}
    case backgroundTransparentBlack300 = "Background/Transparent/Black/300"
    /// {theme.transparent_black_shade3_color}
    case backgroundTransparentBlack500 = "Background/Transparent/Black/500"
    /// {theme.transparent_black_shade4_color}
    case backgroundTransparentBlack600 = "Background/Transparent/Black/600"
    /// {theme.transparent_black_shade5_color}
    case backgroundTransparentBlack800 = "Background/Transparent/Black/800"
    /// {theme.transparent_red_shade1_color}
    case backgroundTransparentRed200 = "Background/Transparent/Red/200"
    /// {theme.transparent_white_shade1_color}
    case backgroundTransparentWhite0 = "Background/Transparent/White/0"
    /// {theme.transparent_white_shade2_color}
    case backgroundTransparentWhite100 = "Background/Transparent/White/100"
    /// {theme.transparent_white_shade3_color}
    case backgroundTransparentWhite200 = "Background/Transparent/White/200"
    /// {theme.transparent_white_shade4_color}
    case backgroundTransparentWhite300 = "Background/Transparent/White/300"
    /// {theme.transparent_white_shade5_color}
    case backgroundTransparentWhite400 = "Background/Transparent/White/400"
    /// {theme.transparent_white_shade6_color}
    case backgroundTransparentWhite600 = "Background/Transparent/White/600"
    /// {theme.transparent_white_shade7_color}
    case backgroundTransparentWhite800 = "Background/Transparent/White/800"
    /// {theme.background_color}
    case backgroundWhiteDefault = "Background/White/Default"
    /// {theme.black_color}
    case blackBlack = "Black/Black"
    /// {theme.white_color}
    case genericWhiteWhite = "Generic/White/White"
    /// {theme.neutral_grey_shade1_color}
    case information200 = "Information/200"
    /// {theme.neutral_grey_shade2_color}
    case information300 = "Information/300"
    /// {theme.neutral_grey_shade3_color}
    case information500 = "Information/500"
    /// {theme.neutral_grey_shade4_color}
    case information700 = "Information/700"
    /// {theme.neutral_grey_shade6_color}
    case information800 = "Information/800"
    /// {theme.white_color}
    case informationWhite = "Information/White"
    /// {theme.primary_shade3_color}
    case primary200 = "Primary/200"
    /// {theme.primary_shade2_color}
    case primary250 = "Primary/250"
    /// {theme.primary_shade1_color}
    case primary400 = "Primary/400"
    /// {theme.primary_color}
    case primary500 = "Primary/500"
    /// {theme.primary_color}
    case primary600 = "Primary/600"
    /// {theme.primary_shade4_color}
    case primary700 = "Primary/700"
    /// {theme.primary_shade4_color}
    case primary800 = "Primary/800"
    /// {theme.white_color}
    case primaryWhite = "Primary/White"
    /// {theme.neutral_grey_shade1_color}
    case secondary200 = "Secondary/200"
    /// {theme.neutral_grey_shade1_color}
    case secondary250 = "Secondary/250"
    /// {theme.neutral_grey_shade1_color}
    case secondary300 = "Secondary/300"
    /// {theme.neutral_grey_shade2_color}
    case secondary400 = "Secondary/400"
    /// {theme.neutral_grey_shade3_color}
    case secondary500 = "Secondary/500"
    /// {theme.neutral_grey_shade4_color}
    case secondary700 = "Secondary/700"
    /// {theme.neutral_grey_shade5_color}
    case secondary750 = "Secondary/750"
    /// {theme.neutral_grey_shade6_color}
    case secondary800 = "Secondary/800"
    /// {theme.white_color}
    case secondaryWhite = "Secondary/White"
    /// {theme.alert_shade1_color}
    case signalAlert400 = "Signal/Alert/400"
    /// {theme.alert_color}
    case signalAlert500 = "Signal/Alert/500"
    /// {theme.alert_color}
    case signalAlert700 = "Signal/Alert/700"
    /// {theme.destructive_shade1_color}
    case signalDestructive200 = "Signal/Destructive/200"
    /// {theme.destructive_shade2_color}
    case signalDestructive300 = "Signal/Destructive/300"
    /// {theme.destructive_shade3_color}
    case signalDestructive400 = "Signal/Destructive/400"
    /// {theme.destructive_shade4_color}
    case signalDestructive500 = "Signal/Destructive/500"
    /// {theme.destructive_shade5_color}
    case signalDestructive700 = "Signal/Destructive/700"
    /// {theme.destructive_shade5_color}
    case signalDestructive800 = "Signal/Destructive/800"
    /// {theme.event_host_bg_color}
    case signalEvent150 = "Signal/Event/150"
    /// {theme.event_host_fg_color}
    case signalEvent500 = "Signal/Event/500"
    /// {theme.alert_color}
    case signalLive500 = "Signal/Live/500"
}

extension AmityColorAlias {
    /// Resolves this alias against the given theme palette.
    func uiColor(theme: AmityThemeColor) -> UIColor {
        switch self {
        case .backgroundBlackDefault: return theme.backgroundColor
        case .backgroundStandardBlackDefault: return theme.backgroundColor
        case .backgroundStandardBlackSubdue: return theme.backgroundShade1Color
        case .backgroundStandardWhiteDefault: return theme.backgroundColor
        case .backgroundTransparentBlack200: return theme.transparentBlackShade1Color
        case .backgroundTransparentBlack300: return theme.transparentBlackShade2Color
        case .backgroundTransparentBlack500: return theme.transparentBlackShade3Color
        case .backgroundTransparentBlack600: return theme.transparentBlackShade4Color
        case .backgroundTransparentBlack800: return theme.transparentBlackShade5Color
        case .backgroundTransparentRed200: return theme.transparentRedShade1Color
        case .backgroundTransparentWhite0: return theme.transparentWhiteShade1Color
        case .backgroundTransparentWhite100: return theme.transparentWhiteShade2Color
        case .backgroundTransparentWhite200: return theme.transparentWhiteShade3Color
        case .backgroundTransparentWhite300: return theme.transparentWhiteShade4Color
        case .backgroundTransparentWhite400: return theme.transparentWhiteShade5Color
        case .backgroundTransparentWhite600: return theme.transparentWhiteShade6Color
        case .backgroundTransparentWhite800: return theme.transparentWhiteShade7Color
        case .backgroundWhiteDefault: return theme.backgroundColor
        case .blackBlack: return AmityFixedColor.shared.black
        case .genericWhiteWhite: return AmityFixedColor.shared.white
        case .information200: return theme.neutralGreyShade1Color
        case .information300: return theme.neutralGreyShade2Color
        case .information500: return theme.neutralGreyShade3Color
        case .information700: return theme.neutralGreyShade4Color
        case .information800: return theme.neutralGreyShade6Color
        case .informationWhite: return AmityFixedColor.shared.white
        case .primary200: return theme.primaryColorShade3
        case .primary250: return theme.primaryColorShade2
        case .primary400: return theme.primaryColorShade1
        case .primary500: return theme.primaryColor
        case .primary600: return theme.primaryColor
        case .primary700: return theme.primaryColorShade4
        case .primary800: return theme.primaryColorShade4
        case .primaryWhite: return AmityFixedColor.shared.white
        case .secondary200: return theme.neutralGreyShade1Color
        case .secondary250: return theme.neutralGreyShade1Color
        case .secondary300: return theme.neutralGreyShade1Color
        case .secondary400: return theme.neutralGreyShade2Color
        case .secondary500: return theme.neutralGreyShade3Color
        case .secondary700: return theme.neutralGreyShade4Color
        case .secondary750: return theme.neutralGreyShade5Color
        case .secondary800: return theme.neutralGreyShade6Color
        case .secondaryWhite: return AmityFixedColor.shared.white
        case .signalAlert400: return theme.alertColorShade1
        case .signalAlert500: return theme.alertColor
        case .signalAlert700: return theme.alertColor
        case .signalDestructive200: return theme.destructiveShade1Color
        case .signalDestructive300: return theme.destructiveShade2Color
        case .signalDestructive400: return theme.destructiveShade3Color
        case .signalDestructive500: return theme.destructiveShade4Color
        case .signalDestructive700: return theme.destructiveShade5Color
        case .signalDestructive800: return theme.destructiveShade5Color
        case .signalEvent150: return AmityFixedColor.shared.eventHostBg
        case .signalEvent500: return AmityFixedColor.shared.eventHost
        case .signalLive500: return theme.alertColor
        }
    }
}

/// Semantic color tokens from the design system. Resolve one against the
/// current theme with `viewConfig.color(_:)`.
enum AmityColorToken: String, CaseIterable {
    case borderAvatarIndicatorDefault = "Border/Avatar/Indicator/Default"
    case borderAvatarProfileDefault = "Border/Avatar/Profile/Default"
    case borderBadgeAtomicBadgeDefault = "Border/Badge/AtomicBadge/Default"
    case borderBadgeLiveStatusLiveDefault = "Border/Badge/Live/Status/Live/Default"
    case borderBadgeSemanticBadgeGeneralDefault = "Border/Badge/SemanticBadge/General/Default"
    case borderChatBubbleInboundDefault = "Border/ChatBubble/Inbound/Default"
    case borderChatBubbleInboundDeleted = "Border/ChatBubble/Inbound/Deleted"
    case borderChatBubbleInboundPressed = "Border/ChatBubble/Inbound/Pressed"
    case borderChatBubbleOutboundDefault = "Border/ChatBubble/Outbound/Default"
    case borderChatBubbleOutboundDeleted = "Border/ChatBubble/Outbound/Deleted"
    case borderChipsFilledDisabled = "Border/Chips/Filled/Disabled"
    case borderChipsFilledEnabled = "Border/Chips/Filled/Enabled"
    case borderChipsOutlinedDisabled = "Border/Chips/Outlined/Disabled"
    case borderChipsOutlinedEnabled = "Border/Chips/Outlined/Enabled"
    case borderInputBoxedInputError = "Border/Input/BoxedInput/Error"
    case borderMainButtonDefaultFilledPrimaryDisabled = "Border/MainButton/Default/Filled/Primary/Disabled"
    case borderMainButtonDefaultFilledPrimaryEnabled = "Border/MainButton/Default/Filled/Primary/Enabled"
    case borderMainButtonDefaultFilledPrimaryHover = "Border/MainButton/Default/Filled/Primary/Hover"
    case borderMainButtonDefaultFilledSecondaryDisabled = "Border/MainButton/Default/Filled/Secondary/Disabled"
    case borderMainButtonDefaultFilledSecondaryEnabled = "Border/MainButton/Default/Filled/Secondary/Enabled"
    case borderMainButtonDefaultFilledSecondaryHover = "Border/MainButton/Default/Filled/Secondary/Hover"
    case borderMainButtonDefaultGhostPrimaryHover = "Border/MainButton/Default/Ghost/Primary/Hover"
    case borderMainButtonDefaultGhostSecondaryHover = "Border/MainButton/Default/Ghost/Secondary/Hover"
    case borderMainButtonDefaultInversePrimaryDisabled = "Border/MainButton/Default/Inverse/Primary/Disabled"
    case borderMainButtonDefaultInversePrimaryEnabled = "Border/MainButton/Default/Inverse/Primary/Enabled"
    case borderMainButtonDefaultInversePrimaryHover = "Border/MainButton/Default/Inverse/Primary/Hover"
    case borderMainButtonDefaultInverseSecondaryDisabled = "Border/MainButton/Default/Inverse/Secondary/Disabled"
    case borderMainButtonDefaultInverseSecondaryEnabled = "Border/MainButton/Default/Inverse/Secondary/Enabled"
    case borderMainButtonDefaultInverseSecondaryHover = "Border/MainButton/Default/Inverse/Secondary/Hover"
    case borderMainButtonDefaultOutlinedPrimaryDisabled = "Border/MainButton/Default/Outlined/Primary/Disabled"
    case borderMainButtonDefaultOutlinedPrimaryEnabled = "Border/MainButton/Default/Outlined/Primary/Enabled"
    case borderMainButtonDefaultOutlinedPrimaryHover = "Border/MainButton/Default/Outlined/Primary/Hover"
    case borderMainButtonDefaultOutlinedSecondaryDisabled = "Border/MainButton/Default/Outlined/Secondary/Disabled"
    case borderMainButtonDefaultOutlinedSecondaryEnabled = "Border/MainButton/Default/Outlined/Secondary/Enabled"
    case borderMainButtonDefaultOutlinedSecondaryHover = "Border/MainButton/Default/Outlined/Secondary/Hover"
    case borderMainButtonDefaultTransparentPrimaryDisabled = "Border/MainButton/Default/Transparent/Primary/Disabled"
    case borderMainButtonDefaultTransparentPrimaryEnabled = "Border/MainButton/Default/Transparent/Primary/Enabled"
    case borderMainButtonDefaultTransparentPrimaryHover = "Border/MainButton/Default/Transparent/Primary/Hover"
    case borderMainButtonDestructiveFilledPrimaryDisabled = "Border/MainButton/Destructive/Filled/Primary/Disabled"
    case borderMainButtonDestructiveFilledPrimaryEnabled = "Border/MainButton/Destructive/Filled/Primary/Enabled"
    case borderMainButtonDestructiveFilledPrimaryHover = "Border/MainButton/Destructive/Filled/Primary/Hover"
    case borderMainButtonDestructiveFilledSecondaryDisabled = "Border/MainButton/Destructive/Filled/Secondary/Disabled"
    case borderMainButtonDestructiveFilledSecondaryEnabled = "Border/MainButton/Destructive/Filled/Secondary/Enabled"
    case borderMainButtonDestructiveFilledSecondaryHover = "Border/MainButton/Destructive/Filled/Secondary/Hover"
    case borderMainButtonDestructiveGhostPrimaryHover = "Border/MainButton/Destructive/Ghost/Primary/Hover"
    case borderMainButtonDestructiveGhostSecondaryHover = "Border/MainButton/Destructive/Ghost/Secondary/Hover"
    case borderMainButtonDestructiveInversePrimaryDisabled = "Border/MainButton/Destructive/Inverse/Primary/Disabled"
    case borderMainButtonDestructiveInversePrimaryEnabled = "Border/MainButton/Destructive/Inverse/Primary/Enabled"
    case borderMainButtonDestructiveInversePrimaryHover = "Border/MainButton/Destructive/Inverse/Primary/Hover"
    case borderMainButtonDestructiveInverseSecondaryDisabled = "Border/MainButton/Destructive/Inverse/Secondary/Disabled"
    case borderMainButtonDestructiveInverseSecondaryEnabled = "Border/MainButton/Destructive/Inverse/Secondary/Enabled"
    case borderMainButtonDestructiveInverseSecondaryHover = "Border/MainButton/Destructive/Inverse/Secondary/Hover"
    case borderMainButtonDestructiveOutlinedPrimaryDisabled = "Border/MainButton/Destructive/Outlined/Primary/Disabled"
    case borderMainButtonDestructiveOutlinedPrimaryEnabled = "Border/MainButton/Destructive/Outlined/Primary/Enabled"
    case borderMainButtonDestructiveOutlinedPrimaryHover = "Border/MainButton/Destructive/Outlined/Primary/Hover"
    case borderMainButtonDestructiveOutlinedSecondaryDisabled = "Border/MainButton/Destructive/Outlined/Secondary/Disabled"
    case borderMainButtonDestructiveOutlinedSecondaryEnabled = "Border/MainButton/Destructive/Outlined/Secondary/Enabled"
    case borderMainButtonDestructiveOutlinedSecondaryHover = "Border/MainButton/Destructive/Outlined/Secondary/Hover"
    case borderReactionReactionAtomDefault = "Border/Reaction/ReactionAtom/Default"
    case borderReactionReactionCountActive = "Border/Reaction/ReactionCount/Active"
    case borderReactionReactionCountDefault = "Border/Reaction/ReactionCount/Default"
    case borderSelectionCheckboxAtomicInactiveDefault = "Border/Selection/CheckboxAtomic/Inactive/Default"
    case borderSelectionCheckboxAtomicInactiveDisabled = "Border/Selection/CheckboxAtomic/Inactive/Disabled"
    case borderSelectionRadioAtomicInactiveDefault = "Border/Selection/RadioAtomic/Inactive/Default"
    case borderSelectionRadioAtomicInactiveDisabled = "Border/Selection/RadioAtomic/Inactive/Disabled"
    case borderSideNavigationDefault = "Border/SideNavigation/Default"
    case borderTabPillActive = "Border/Tab/Pill/Active"
    case borderTabPillDefault = "Border/Tab/Pill/Default"
    case borderTabPillDisabled = "Border/Tab/Pill/Disabled"
    case borderTabPillHover = "Border/Tab/Pill/Hover"
    case borderTabPillPress = "Border/Tab/Pill/Press"
    case borderToggleBackgroundActiveDisabled = "Border/Toggle/Background/Active/Disabled"
    case borderToggleBackgroundActiveEnabled = "Border/Toggle/Background/Active/Enabled"
    case borderToggleBackgroundActiveFocused = "Border/Toggle/Background/Active/Focused"
    case borderToggleBackgroundActiveHovered = "Border/Toggle/Background/Active/Hovered"
    case borderToggleBackgroundActivePressed = "Border/Toggle/Background/Active/Pressed"
    case borderToggleBackgroundInactiveDisabled = "Border/Toggle/Background/Inactive/Disabled"
    case borderToggleBackgroundInactiveEnabled = "Border/Toggle/Background/Inactive/Enabled"
    case borderToggleBackgroundInactiveFocused = "Border/Toggle/Background/Inactive/Focused"
    case borderToggleBackgroundInactiveHovered = "Border/Toggle/Background/Inactive/Hovered"
    case borderToggleBackgroundInactivePressed = "Border/Toggle/Background/Inactive/Pressed"
    case borderToggleThumbActiveFocused = "Border/Toggle/Thumb/Active/Focused"
    case borderToggleThumbActiveHovered = "Border/Toggle/Thumb/Active/Hovered"
    case borderToggleThumbActivePressed = "Border/Toggle/Thumb/Active/Pressed"
    case borderToggleThumbInactiveFocused = "Border/Toggle/Thumb/Inactive/Focused"
    case borderToggleThumbInactiveHovered = "Border/Toggle/Thumb/Inactive/Hovered"
    case borderToggleThumbInactivePressed = "Border/Toggle/Thumb/Inactive/Pressed"
    case iconActionButtonSplitButtonDefault = "Icon/ActionButton/SplitButton/Default"
    case iconActionButtonSplitButtonDisabled = "Icon/ActionButton/SplitButton/Disabled"
    case iconActionButtonSplitButtonHover = "Icon/ActionButton/SplitButton/Hover"
    case iconAvatarDefault = "Icon/Avatar/Default"
    case iconBadgeAtomicBadgeDefault = "Icon/Badge/AtomicBadge/Default"
    case iconBadgeAtomicBadgeInverse = "Icon/Badge/AtomicBadge/Inverse"
    case iconBadgeDefault = "Icon/Badge/Default"
    case iconBadgeSemanticBadgeChatArchivedDefault = "Icon/Badge/SemanticBadge/Chat/Archived/Default"
    case iconBadgeSemanticBadgeChatMentionDefault = "Icon/Badge/SemanticBadge/Chat/Mention/Default"
    case iconBadgeSemanticBadgeChatPrivateDefault = "Icon/Badge/SemanticBadge/Chat/Private/Default"
    case iconBadgeSemanticBadgeCommunityGeneralDefault = "Icon/Badge/SemanticBadge/Community/General/Default"
    case iconBadgeSemanticBadgeCommunityOfficialDefault = "Icon/Badge/SemanticBadge/Community/Official/Default"
    case iconBadgeSemanticBadgeCommunityPrivateDefault = "Icon/Badge/SemanticBadge/Community/Private/Default"
    case iconBadgeSemanticBadgeEventHostDefault = "Icon/Badge/SemanticBadge/Event/Host/Default"
    case iconBadgeSemanticBadgeLiveAlertDefault = "Icon/Badge/SemanticBadge/Live/Alert/Default"
    case iconBadgeSemanticBadgeLiveGeneralDefault = "Icon/Badge/SemanticBadge/Live/General/Default"
    case iconBadgeSemanticBadgePostStatusSponsoredDefault = "Icon/Badge/SemanticBadge/PostStatus/Sponsored/Default"
    case iconBadgeSemanticBadgeUserStatusBannedDefault = "Icon/Badge/SemanticBadge/UserStatus/Banned/Default"
    case iconBadgeSemanticBadgeUserStatusBrandDefault = "Icon/Badge/SemanticBadge/UserStatus/Brand/Default"
    case iconBadgeSemanticBadgeUserStatusModeratorDefault = "Icon/Badge/SemanticBadge/UserStatus/Moderator/Default"
    case iconBadgeSemanticBadgeUserStatusMutedDefault = "Icon/Badge/SemanticBadge/UserStatus/Muted/Default"
    case iconBadgeSemanticBadgeUserStatusPrivateDefault = "Icon/Badge/SemanticBadge/UserStatus/Private/Default"
    case iconBannerDefaultDescriptionGeneral = "Icon/Banner/Default/Description/General"
    case iconBannerDefaultLeadingIconGeneral = "Icon/Banner/Default/Leading/Icon/General"
    case iconBannerDefaultTrailingIconGeneral = "Icon/Banner/Default/Trailing/Icon/General"
    case iconBannerSubdueDescriptionGeneral = "Icon/Banner/Subdue/Description/General"
    case iconBannerSubdueLeadingIconGeneral = "Icon/Banner/Subdue/Leading/Icon/General"
    case iconBannerSubdueTrailingIconGeneral = "Icon/Banner/Subdue/Trailing/Icon/General"
    case iconChatBubbleInboundHeaderRepliedToDefault = "Icon/ChatBubble/Inbound/Header/RepliedTo/Default"
    case iconChatBubbleInboundMessagesDeleted = "Icon/ChatBubble/Inbound/Messages/Deleted"
    case iconChatBubbleInboundSeeMoreDefault = "Icon/ChatBubble/Inbound/SeeMore/Default"
    case iconChatBubbleOutboundDefault = "Icon/ChatBubble/Outbound/Default"
    case iconChatBubbleOutboundHeaderRepliedToDefault = "Icon/ChatBubble/Outbound/Header/RepliedTo/Default"
    case iconChatBubbleOutboundMessagesDeleted = "Icon/ChatBubble/Outbound/Messages/Deleted"
    case iconChatBubbleOutboundSeeMoreDefault = "Icon/ChatBubble/Outbound/SeeMore/Default"
    case iconCustomToastDefault = "Icon/CustomToast/Default"
    case iconEmptyStateIconDefault = "Icon/EmptyState/Icon/Default"
    case iconFeaturedIconSolid = "Icon/FeaturedIcon/Solid"
    case iconFeaturedIconTinted = "Icon/FeaturedIcon/Tinted"
    case iconFloatingButtonDefault = "Icon/FloatingButton/Default"
    case iconGeneralDefault = "Icon/General/Default"
    case iconGeneralInverse = "Icon/General/Inverse"
    case iconIconButtonFilledPrimaryDefault = "Icon/IconButton/Filled/Primary/Default"
    case iconIconButtonFilledPrimaryDisabled = "Icon/IconButton/Filled/Primary/Disabled"
    case iconIconButtonFilledPrimaryHovered = "Icon/IconButton/Filled/Primary/Hovered"
    case iconIconButtonFilledSecondaryDefault = "Icon/IconButton/Filled/Secondary/Default"
    case iconIconButtonFilledSecondaryDisabled = "Icon/IconButton/Filled/Secondary/Disabled"
    case iconIconButtonFilledSecondaryHovered = "Icon/IconButton/Filled/Secondary/Hovered"
    case iconIconButtonGhostPrimaryDefault = "Icon/IconButton/Ghost/Primary/Default"
    case iconIconButtonGhostPrimaryDisabled = "Icon/IconButton/Ghost/Primary/Disabled"
    case iconIconButtonGhostPrimaryHovered = "Icon/IconButton/Ghost/Primary/Hovered"
    case iconIconButtonGhostSecondaryDefault = "Icon/IconButton/Ghost/Secondary/Default"
    case iconIconButtonGhostSecondaryDisabled = "Icon/IconButton/Ghost/Secondary/Disabled"
    case iconIconButtonGhostSecondaryHovered = "Icon/IconButton/Ghost/Secondary/Hovered"
    case iconIconButtonTransparentPrimaryDefault = "Icon/IconButton/Transparent/Primary/Default"
    case iconIconButtonTransparentPrimaryDisabled = "Icon/IconButton/Transparent/Primary/Disabled"
    case iconIconButtonTransparentPrimaryHovered = "Icon/IconButton/Transparent/Primary/Hovered"
    case iconInputChipInputDefault = "Icon/Input/ChipInput/Default"
    case iconInputChipInputDisabled = "Icon/Input/ChipInput/Disabled"
    case iconInputChipInputError = "Icon/Input/ChipInput/Error"
    case iconInputTextInputDefault = "Icon/Input/TextInput/Default"
    case iconInputTextInputDisabled = "Icon/Input/TextInput/Disabled"
    case iconInputTextInputError = "Icon/Input/TextInput/Error"
    case iconListDescriptionGeneral = "Icon/List/Description/General"
    case iconListHeaderGeneral = "Icon/List/Header/General"
    case iconListLeadingActive = "Icon/List/Leading/Active"
    case iconListLeadingDefaultActive = "Icon/List/Leading/Default/Active"
    case iconListLeadingDefaultDefault = "Icon/List/Leading/Default/Default"
    case iconListLeadingDefaultDisabled = "Icon/List/Leading/Default/Disabled"
    case iconListLeadingDefaultHover = "Icon/List/Leading/Default/Hover"
    case iconListLeadingDestructiveDefault = "Icon/List/Leading/Destructive/Default"
    case iconListLeadingDestructiveDisabled = "Icon/List/Leading/Destructive/Disabled"
    case iconListLeadingDestructiveHover = "Icon/List/Leading/Destructive/Hover"
    case iconListLeadingDisabled = "Icon/List/Leading/Disabled"
    case iconListLeadingHover = "Icon/List/Leading/Hover"
    case iconLoadersRefresherGeneral = "Icon/Loaders/Refresher/General"
    case iconLoadersUploadControllerDefault = "Icon/Loaders/UploadController/Default"
    case iconMainButtonDefaultDescriptionPrimaryDisabled = "Icon/MainButton/Default/Description/Primary/Disabled"
    case iconMainButtonDefaultDescriptionPrimaryEnabled = "Icon/MainButton/Default/Description/Primary/Enabled"
    case iconMainButtonDefaultDescriptionPrimaryHover = "Icon/MainButton/Default/Description/Primary/Hover"
    case iconMainButtonDefaultDescriptionSecondaryDisabled = "Icon/MainButton/Default/Description/Secondary/Disabled"
    case iconMainButtonDefaultDescriptionSecondaryEnabled = "Icon/MainButton/Default/Description/Secondary/Enabled"
    case iconMainButtonDefaultDescriptionSecondaryHover = "Icon/MainButton/Default/Description/Secondary/Hover"
    case iconMainButtonDefaultFilledPrimaryDisabled = "Icon/MainButton/Default/Filled/Primary/Disabled"
    case iconMainButtonDefaultFilledPrimaryEnabled = "Icon/MainButton/Default/Filled/Primary/Enabled"
    case iconMainButtonDefaultFilledPrimaryHover = "Icon/MainButton/Default/Filled/Primary/Hover"
    case iconMainButtonDefaultFilledSecondaryDisabled = "Icon/MainButton/Default/Filled/Secondary/Disabled"
    case iconMainButtonDefaultFilledSecondaryEnabled = "Icon/MainButton/Default/Filled/Secondary/Enabled"
    case iconMainButtonDefaultFilledSecondaryHover = "Icon/MainButton/Default/Filled/Secondary/Hover"
    case iconMainButtonDefaultGhostPrimaryDisabled = "Icon/MainButton/Default/Ghost/Primary/Disabled"
    case iconMainButtonDefaultGhostPrimaryEnabled = "Icon/MainButton/Default/Ghost/Primary/Enabled"
    case iconMainButtonDefaultGhostPrimaryHover = "Icon/MainButton/Default/Ghost/Primary/Hover"
    case iconMainButtonDefaultGhostSecondaryDisabled = "Icon/MainButton/Default/Ghost/Secondary/Disabled"
    case iconMainButtonDefaultGhostSecondaryEnabled = "Icon/MainButton/Default/Ghost/Secondary/Enabled"
    case iconMainButtonDefaultGhostSecondaryHover = "Icon/MainButton/Default/Ghost/Secondary/Hover"
    case iconMainButtonDefaultInversePrimaryDisabled = "Icon/MainButton/Default/Inverse/Primary/Disabled"
    case iconMainButtonDefaultInversePrimaryEnabled = "Icon/MainButton/Default/Inverse/Primary/Enabled"
    case iconMainButtonDefaultInversePrimaryHover = "Icon/MainButton/Default/Inverse/Primary/Hover"
    case iconMainButtonDefaultInverseSecondaryDisabled = "Icon/MainButton/Default/Inverse/Secondary/Disabled"
    case iconMainButtonDefaultInverseSecondaryEnabled = "Icon/MainButton/Default/Inverse/Secondary/Enabled"
    case iconMainButtonDefaultInverseSecondaryHover = "Icon/MainButton/Default/Inverse/Secondary/Hover"
    case iconMainButtonDefaultLinkPrimaryDisabled = "Icon/MainButton/Default/Link/Primary/Disabled"
    case iconMainButtonDefaultLinkPrimaryEnabled = "Icon/MainButton/Default/Link/Primary/Enabled"
    case iconMainButtonDefaultLinkPrimaryHover = "Icon/MainButton/Default/Link/Primary/Hover"
    case iconMainButtonDefaultLinkSecondaryDisabled = "Icon/MainButton/Default/Link/Secondary/Disabled"
    case iconMainButtonDefaultLinkSecondaryEnabled = "Icon/MainButton/Default/Link/Secondary/Enabled"
    case iconMainButtonDefaultLinkSecondaryHover = "Icon/MainButton/Default/Link/Secondary/Hover"
    case iconMainButtonDefaultOutlinedPrimaryDisabled = "Icon/MainButton/Default/Outlined/Primary/Disabled"
    case iconMainButtonDefaultOutlinedPrimaryEnabled = "Icon/MainButton/Default/Outlined/Primary/Enabled"
    case iconMainButtonDefaultOutlinedPrimaryHover = "Icon/MainButton/Default/Outlined/Primary/Hover"
    case iconMainButtonDefaultOutlinedSecondaryDisabled = "Icon/MainButton/Default/Outlined/Secondary/Disabled"
    case iconMainButtonDefaultOutlinedSecondaryEnabled = "Icon/MainButton/Default/Outlined/Secondary/Enabled"
    case iconMainButtonDefaultOutlinedSecondaryHover = "Icon/MainButton/Default/Outlined/Secondary/Hover"
    case iconMainButtonDefaultTransparentPrimaryDisabled = "Icon/MainButton/Default/Transparent/Primary/Disabled"
    case iconMainButtonDefaultTransparentPrimaryEnabled = "Icon/MainButton/Default/Transparent/Primary/Enabled"
    case iconMainButtonDefaultTransparentPrimaryHover = "Icon/MainButton/Default/Transparent/Primary/Hover"
    case iconMainButtonDestructiveDescriptionPrimaryDisabled = "Icon/MainButton/Destructive/Description/Primary/Disabled"
    case iconMainButtonDestructiveDescriptionPrimaryEnabled = "Icon/MainButton/Destructive/Description/Primary/Enabled"
    case iconMainButtonDestructiveDescriptionPrimaryHover = "Icon/MainButton/Destructive/Description/Primary/Hover"
    case iconMainButtonDestructiveDescriptionSecondaryDisabled = "Icon/MainButton/Destructive/Description/Secondary/Disabled"
    case iconMainButtonDestructiveDescriptionSecondaryEnabled = "Icon/MainButton/Destructive/Description/Secondary/Enabled"
    case iconMainButtonDestructiveDescriptionSecondaryHover = "Icon/MainButton/Destructive/Description/Secondary/Hover"
    case iconMainButtonDestructiveFilledPrimaryDisabled = "Icon/MainButton/Destructive/Filled/Primary/Disabled"
    case iconMainButtonDestructiveFilledPrimaryEnabled = "Icon/MainButton/Destructive/Filled/Primary/Enabled"
    case iconMainButtonDestructiveFilledPrimaryHover = "Icon/MainButton/Destructive/Filled/Primary/Hover"
    case iconMainButtonDestructiveFilledSecondaryDisabled = "Icon/MainButton/Destructive/Filled/Secondary/Disabled"
    case iconMainButtonDestructiveFilledSecondaryEnabled = "Icon/MainButton/Destructive/Filled/Secondary/Enabled"
    case iconMainButtonDestructiveFilledSecondaryHover = "Icon/MainButton/Destructive/Filled/Secondary/Hover"
    case iconMainButtonDestructiveGhostPrimaryDisabled = "Icon/MainButton/Destructive/Ghost/Primary/Disabled"
    case iconMainButtonDestructiveGhostPrimaryEnabled = "Icon/MainButton/Destructive/Ghost/Primary/Enabled"
    case iconMainButtonDestructiveGhostPrimaryHover = "Icon/MainButton/Destructive/Ghost/Primary/Hover"
    case iconMainButtonDestructiveGhostSecondaryDisabled = "Icon/MainButton/Destructive/Ghost/Secondary/Disabled"
    case iconMainButtonDestructiveGhostSecondaryEnabled = "Icon/MainButton/Destructive/Ghost/Secondary/Enabled"
    case iconMainButtonDestructiveGhostSecondaryHover = "Icon/MainButton/Destructive/Ghost/Secondary/Hover"
    case iconMainButtonDestructiveInversePrimaryDisabled = "Icon/MainButton/Destructive/Inverse/Primary/Disabled"
    case iconMainButtonDestructiveInversePrimaryEnabled = "Icon/MainButton/Destructive/Inverse/Primary/Enabled"
    case iconMainButtonDestructiveInversePrimaryHover = "Icon/MainButton/Destructive/Inverse/Primary/Hover"
    case iconMainButtonDestructiveInverseSecondaryDisabled = "Icon/MainButton/Destructive/Inverse/Secondary/Disabled"
    case iconMainButtonDestructiveInverseSecondaryEnabled = "Icon/MainButton/Destructive/Inverse/Secondary/Enabled"
    case iconMainButtonDestructiveInverseSecondaryHover = "Icon/MainButton/Destructive/Inverse/Secondary/Hover"
    case iconMainButtonDestructiveLinkPrimaryDisabled = "Icon/MainButton/Destructive/Link/Primary/Disabled"
    case iconMainButtonDestructiveLinkPrimaryEnabled = "Icon/MainButton/Destructive/Link/Primary/Enabled"
    case iconMainButtonDestructiveLinkPrimaryHover = "Icon/MainButton/Destructive/Link/Primary/Hover"
    case iconMainButtonDestructiveLinkSecondaryDisabled = "Icon/MainButton/Destructive/Link/Secondary/Disabled"
    case iconMainButtonDestructiveLinkSecondaryEnabled = "Icon/MainButton/Destructive/Link/Secondary/Enabled"
    case iconMainButtonDestructiveLinkSecondaryHover = "Icon/MainButton/Destructive/Link/Secondary/Hover"
    case iconMainButtonDestructiveOutlinedPrimaryDisabled = "Icon/MainButton/Destructive/Outlined/Primary/Disabled"
    case iconMainButtonDestructiveOutlinedPrimaryEnabled = "Icon/MainButton/Destructive/Outlined/Primary/Enabled"
    case iconMainButtonDestructiveOutlinedPrimaryHover = "Icon/MainButton/Destructive/Outlined/Primary/Hover"
    case iconMainButtonDestructiveOutlinedSecondaryDisabled = "Icon/MainButton/Destructive/Outlined/Secondary/Disabled"
    case iconMainButtonDestructiveOutlinedSecondaryEnabled = "Icon/MainButton/Destructive/Outlined/Secondary/Enabled"
    case iconMainButtonDestructiveOutlinedSecondaryHover = "Icon/MainButton/Destructive/Outlined/Secondary/Hover"
    case iconMediaImageBroken = "Icon/Media/Image/Broken"
    case iconMediaVideoBroken = "Icon/Media/Video/Broken"
    case iconSelectionCheckboxAtomicDefault = "Icon/Selection/CheckboxAtomic/Default"
    case iconSelectionCheckboxAtomicDisabled = "Icon/Selection/CheckboxAtomic/Disabled"
    case iconSelectionRadioAtomicDefault = "Icon/Selection/RadioAtomic/Default"
    case iconSelectionRadioAtomicDisabled = "Icon/Selection/RadioAtomic/Disabled"
    case iconSheetsDefaultDefault = "Icon/Sheets/Default/Default"
    case iconSquareButtonDefaultPrimaryDefault = "Icon/SquareButton/Default/Primary/Default"
    case iconSquareButtonDefaultPrimaryDisabled = "Icon/SquareButton/Default/Primary/Disabled"
    case iconSquareButtonDefaultPrimaryHover = "Icon/SquareButton/Default/Primary/Hover"
    case iconSquareButtonDefaultSecondaryDefault = "Icon/SquareButton/Default/Secondary/Default"
    case iconSquareButtonDefaultSecondaryDisabled = "Icon/SquareButton/Default/Secondary/Disabled"
    case iconSquareButtonDefaultSecondaryHover = "Icon/SquareButton/Default/Secondary/Hover"
    case iconSquareButtonDestructiveDefault = "Icon/SquareButton/Destructive/Default"
    case iconSquareButtonDestructiveDisabled = "Icon/SquareButton/Destructive/Disabled"
    case iconSquareButtonDestructiveHover = "Icon/SquareButton/Destructive/Hover"
    case iconTabActive = "Icon/Tab/Active"
    case iconTabDefault = "Icon/Tab/Default"
    case iconTabDisabled = "Icon/Tab/Disabled"
    case iconTabHover = "Icon/Tab/Hover"
    case iconTabPress = "Icon/Tab/Press"
    case iconToggleActiveGeneral = "Icon/Toggle/Active/General"
    case iconToggleInactiveGeneral = "Icon/Toggle/Inactive/General"
    case lineChatBubbleInboundDividerDefault = "Line/ChatBubble/Inbound/Divider/Default"
    case lineChatBubbleOutboundDividerDefault = "Line/ChatBubble/Outbound/Divider/Default"
    case lineCommentBubbleConnectorEndDefault = "Line/CommentBubble/Connector/End/Default"
    case lineCommentBubbleConnectorMiddleDefault = "Line/CommentBubble/Connector/Middle/Default"
    case lineCommentBubbleConnectorStartDefault = "Line/CommentBubble/Connector/Start/Default"
    case lineDividerContentDefault = "Line/Divider/Content/Default"
    case lineDividerPostDefault = "Line/Divider/Post/Default"
    case lineInputChipInputUnderlinedDefault = "Line/Input/ChipInput/Underlined/Default"
    case lineInputChipInputUnderlinedDisabled = "Line/Input/ChipInput/Underlined/Disabled"
    case lineInputChipInputUnderlinedError = "Line/Input/ChipInput/Underlined/Error"
    case lineInputTextInputUnderlinedDefault = "Line/Input/TextInput/Underlined/Default"
    case lineInputTextInputUnderlinedDisabled = "Line/Input/TextInput/Underlined/Disabled"
    case lineInputTextInputUnderlinedError = "Line/Input/TextInput/Underlined/Error"
    case lineTabIconActive = "Line/Tab/Icon/Active"
    case lineTabUnderlinedActive = "Line/Tab/Underlined/Active"
    case surfaceActionButtonsCaptureButtonGeneral = "Surface/ActionButtons/CaptureButton/General"
    case surfaceActionButtonsHover = "Surface/ActionButtons/Hover"
    case surfaceActionButtonsPressed = "Surface/ActionButtons/Pressed"
    case surfaceActionButtonsSplitButtonEnabled = "Surface/ActionButtons/SplitButton/Enabled"
    case surfaceActionButtonsSplitButtonHover = "Surface/ActionButtons/SplitButton/Hover"
    case surfaceActionButtonsSplitButtonPressed = "Surface/ActionButtons/SplitButton/Pressed"
    case surfaceAlertDialogBackgroundDefault = "Surface/AlertDialog/Background/Default"
    case surfaceAvatarProfileDefault = "Surface/Avatar/Profile/Default"
    case surfaceBackgroundDefault = "Surface/Background/Default"
    case surfaceBackgroundSubdue = "Surface/Background/Subdue"
    case surfaceBadgeAtomicBadgeFilledDefault = "Surface/Badge/AtomicBadge/Filled/Default"
    case surfaceBadgeSemanticBadgeChatArchived = "Surface/Badge/SemanticBadge/Chat/Archived"
    case surfaceBadgeSemanticBadgeChatMention = "Surface/Badge/SemanticBadge/Chat/Mention"
    case surfaceBadgeSemanticBadgeChatPrivate = "Surface/Badge/SemanticBadge/Chat/Private"
    case surfaceBadgeSemanticBadgeCommunityGeneral = "Surface/Badge/SemanticBadge/Community/General"
    case surfaceBadgeSemanticBadgeCommunityOfficial = "Surface/Badge/SemanticBadge/Community/Official"
    case surfaceBadgeSemanticBadgeEventDefault = "Surface/Badge/SemanticBadge/Event/Default"
    case surfaceBadgeSemanticBadgeEventHost = "Surface/Badge/SemanticBadge/Event/Host"
    case surfaceBadgeSemanticBadgeGeneralDot = "Surface/Badge/SemanticBadge/General/Dot"
    case surfaceBadgeSemanticBadgeGeneralDuration = "Surface/Badge/SemanticBadge/General/Duration"
    case surfaceBadgeSemanticBadgeGeneralNotification = "Surface/Badge/SemanticBadge/General/Notification"
    case surfaceBadgeSemanticBadgeGeneralSelection = "Surface/Badge/SemanticBadge/General/Selection"
    case surfaceBadgeSemanticBadgeLiveAlert = "Surface/Badge/SemanticBadge/Live/Alert"
    case surfaceBadgeSemanticBadgeLiveIndicator = "Surface/Badge/SemanticBadge/Live/Indicator"
    case surfaceBadgeSemanticBadgeLiveInformation = "Surface/Badge/SemanticBadge/Live/Information"
    case surfaceBadgeSemanticBadgePostStatusFeatured = "Surface/Badge/SemanticBadge/PostStatus/Featured"
    case surfaceBadgeSemanticBadgePostStatusSponsored = "Surface/Badge/SemanticBadge/PostStatus/Sponsored"
    case surfaceBadgeSemanticBadgePostStatusTotalMedia = "Surface/Badge/SemanticBadge/PostStatus/TotalMedia"
    case surfaceBadgeSemanticBadgeUserStatusModerator = "Surface/Badge/SemanticBadge/UserStatus/Moderator"
    case surfaceBannerDefaultGeneral = "Surface/Banner/Default/General"
    case surfaceBannerSubdueGeneral = "Surface/Banner/Subdue/General"
    case surfaceCardPreviewLinkDefault = "Surface/Card/PreviewLink/Default"
    case surfaceCardPreviewLinkSkeleton = "Surface/Card/PreviewLink/Skeleton"
    case surfaceCardPreviewLinkUnavailable = "Surface/Card/PreviewLink/Unavailable"
    case surfaceChatBubbleMessageInboundDefault = "Surface/ChatBubble/Message/Inbound/Default"
    case surfaceChatBubbleMessageInboundDeleted = "Surface/ChatBubble/Message/Inbound/Deleted"
    case surfaceChatBubbleMessageInboundPressed = "Surface/ChatBubble/Message/Inbound/Pressed"
    case surfaceChatBubbleMessageOutboundDefault = "Surface/ChatBubble/Message/Outbound/Default"
    case surfaceChatBubbleMessageOutboundDeleted = "Surface/ChatBubble/Message/Outbound/Deleted"
    case surfaceChatBubbleMessageOutboundFailed = "Surface/ChatBubble/Message/Outbound/Failed"
    case surfaceChatBubbleMessageOutboundPressed = "Surface/ChatBubble/Message/Outbound/Pressed"
    case surfaceChatBubbleReplyMessageDefault = "Surface/ChatBubble/Reply/Message/Default"
    case surfaceChatBubbleReplyMessageFailed = "Surface/ChatBubble/Reply/Message/Failed"
    case surfaceChatBubbleReplyOverlayDefault = "Surface/ChatBubble/Reply/Overlay/Default"
    case surfaceChipsFilledDefault = "Surface/Chips/Filled/Default"
    case surfaceChipsFilledDisabled = "Surface/Chips/Filled/Disabled"
    case surfaceChipsOutlinedDefault = "Surface/Chips/Outlined/Default"
    case surfaceChipsOutlinedDisabled = "Surface/Chips/Outlined/Disabled"
    case surfaceCustomToastDefaultDefault = "Surface/CustomToast/Default/Default"
    case surfaceDateAndTimeDateSeparatorDefault = "Surface/Date&Time/DateSeparator/Default"
    case surfaceFeaturedIconSolid = "Surface/FeaturedIcon/Solid"
    case surfaceFeaturedIconTinted = "Surface/FeaturedIcon/Tinted"
    case surfaceFloatingButtonEnabled = "Surface/FloatingButton/Enabled"
    case surfaceFloatingButtonHover = "Surface/FloatingButton/Hover"
    case surfaceFloatingButtonPressed = "Surface/FloatingButton/Pressed"
    case surfaceIconButtonFilledPrimaryDisabled = "Surface/IconButton/Filled/Primary/Disabled"
    case surfaceIconButtonFilledPrimaryEnabled = "Surface/IconButton/Filled/Primary/Enabled"
    case surfaceIconButtonFilledPrimaryHover = "Surface/IconButton/Filled/Primary/Hover"
    case surfaceIconButtonFilledSecondaryDisabled = "Surface/IconButton/Filled/Secondary/Disabled"
    case surfaceIconButtonFilledSecondaryEnabled = "Surface/IconButton/Filled/Secondary/Enabled"
    case surfaceIconButtonFilledSecondaryHover = "Surface/IconButton/Filled/Secondary/Hover"
    case surfaceIconButtonGhostPrimaryHover = "Surface/IconButton/Ghost/Primary/Hover"
    case surfaceIconButtonGhostSecondaryHover = "Surface/IconButton/Ghost/Secondary/Hover"
    case surfaceIconButtonTransparentPrimaryDisabled = "Surface/IconButton/Transparent/Primary/Disabled"
    case surfaceIconButtonTransparentPrimaryEnabled = "Surface/IconButton/Transparent/Primary/Enabled"
    case surfaceIconButtonTransparentPrimaryHover = "Surface/IconButton/Transparent/Primary/Hover"
    case surfaceInputBoxedInputDefault = "Surface/Input/BoxedInput/Default"
    case surfaceListDefaultActive = "Surface/List/Default/Active"
    case surfaceListDefaultDefault = "Surface/List/Default/Default"
    case surfaceListDefaultDisabled = "Surface/List/Default/Disabled"
    case surfaceListDefaultHover = "Surface/List/Default/Hover"
    case surfaceListDestructiveDefault = "Surface/List/Destructive/Default"
    case surfaceListDestructiveDisabled = "Surface/List/Destructive/Disabled"
    case surfaceListDestructiveHover = "Surface/List/Destructive/Hover"
    case surfaceListSkeletonSkeleton = "Surface/List/Skeleton/Skeleton"
    case surfaceLoadersRefresherGeneral = "Surface/Loaders/Refresher/General"
    case surfaceLoadersSpinnerBackground = "Surface/Loaders/Spinner/Background"
    case surfaceLoadersSpinnerIcon = "Surface/Loaders/Spinner/Icon"
    case surfaceLoadersUploadControllerBackground = "Surface/Loaders/UploadController/Background"
    case surfaceLoadersUploadControllerLoader = "Surface/Loaders/UploadController/Loader"
    case surfaceMainButtonDefaultFilledPrimaryDisabled = "Surface/MainButton/Default/Filled/Primary/Disabled"
    case surfaceMainButtonDefaultFilledPrimaryEnabled = "Surface/MainButton/Default/Filled/Primary/Enabled"
    case surfaceMainButtonDefaultFilledPrimaryHover = "Surface/MainButton/Default/Filled/Primary/Hover"
    case surfaceMainButtonDefaultFilledSecondaryDisabled = "Surface/MainButton/Default/Filled/Secondary/Disabled"
    case surfaceMainButtonDefaultFilledSecondaryEnabled = "Surface/MainButton/Default/Filled/Secondary/Enabled"
    case surfaceMainButtonDefaultFilledSecondaryHover = "Surface/MainButton/Default/Filled/Secondary/Hover"
    case surfaceMainButtonDefaultGhostPrimaryHover = "Surface/MainButton/Default/Ghost/Primary/Hover"
    case surfaceMainButtonDefaultGhostSecondaryHover = "Surface/MainButton/Default/Ghost/Secondary/Hover"
    case surfaceMainButtonDefaultInversePrimaryDisabled = "Surface/MainButton/Default/Inverse/Primary/Disabled"
    case surfaceMainButtonDefaultInversePrimaryEnabled = "Surface/MainButton/Default/Inverse/Primary/Enabled"
    case surfaceMainButtonDefaultInversePrimaryHover = "Surface/MainButton/Default/Inverse/Primary/Hover"
    case surfaceMainButtonDefaultInverseSecondaryDisabled = "Surface/MainButton/Default/Inverse/Secondary/Disabled"
    case surfaceMainButtonDefaultInverseSecondaryEnabled = "Surface/MainButton/Default/Inverse/Secondary/Enabled"
    case surfaceMainButtonDefaultInverseSecondaryHover = "Surface/MainButton/Default/Inverse/Secondary/Hover"
    case surfaceMainButtonDefaultOutlinedPrimaryDisabled = "Surface/MainButton/Default/Outlined/Primary/Disabled"
    case surfaceMainButtonDefaultOutlinedPrimaryEnabled = "Surface/MainButton/Default/Outlined/Primary/Enabled"
    case surfaceMainButtonDefaultOutlinedPrimaryHover = "Surface/MainButton/Default/Outlined/Primary/Hover"
    case surfaceMainButtonDefaultOutlinedSecondaryDisabled = "Surface/MainButton/Default/Outlined/Secondary/Disabled"
    case surfaceMainButtonDefaultOutlinedSecondaryEnabled = "Surface/MainButton/Default/Outlined/Secondary/Enabled"
    case surfaceMainButtonDefaultOutlinedSecondaryHover = "Surface/MainButton/Default/Outlined/Secondary/Hover"
    case surfaceMainButtonDefaultTransparentPrimaryDisabled = "Surface/MainButton/Default/Transparent/Primary/Disabled"
    case surfaceMainButtonDefaultTransparentPrimaryEnabled = "Surface/MainButton/Default/Transparent/Primary/Enabled"
    case surfaceMainButtonDefaultTransparentPrimaryHover = "Surface/MainButton/Default/Transparent/Primary/Hover"
    case surfaceMainButtonDestructiveFilledPrimaryDisabled = "Surface/MainButton/Destructive/Filled/Primary/Disabled"
    case surfaceMainButtonDestructiveFilledPrimaryEnabled = "Surface/MainButton/Destructive/Filled/Primary/Enabled"
    case surfaceMainButtonDestructiveFilledPrimaryHover = "Surface/MainButton/Destructive/Filled/Primary/Hover"
    case surfaceMainButtonDestructiveFilledSecondaryDisabled = "Surface/MainButton/Destructive/Filled/Secondary/Disabled"
    case surfaceMainButtonDestructiveFilledSecondaryEnabled = "Surface/MainButton/Destructive/Filled/Secondary/Enabled"
    case surfaceMainButtonDestructiveFilledSecondaryHover = "Surface/MainButton/Destructive/Filled/Secondary/Hover"
    case surfaceMainButtonDestructiveGhostPrimaryHover = "Surface/MainButton/Destructive/Ghost/Primary/Hover"
    case surfaceMainButtonDestructiveGhostSecondaryHover = "Surface/MainButton/Destructive/Ghost/Secondary/Hover"
    case surfaceMainButtonDestructiveInversePrimaryDisabled = "Surface/MainButton/Destructive/Inverse/Primary/Disabled"
    case surfaceMainButtonDestructiveInversePrimaryEnabled = "Surface/MainButton/Destructive/Inverse/Primary/Enabled"
    case surfaceMainButtonDestructiveInversePrimaryHover = "Surface/MainButton/Destructive/Inverse/Primary/Hover"
    case surfaceMainButtonDestructiveInverseSecondaryDisabled = "Surface/MainButton/Destructive/Inverse/Secondary/Disabled"
    case surfaceMainButtonDestructiveInverseSecondaryEnabled = "Surface/MainButton/Destructive/Inverse/Secondary/Enabled"
    case surfaceMainButtonDestructiveInverseSecondaryHover = "Surface/MainButton/Destructive/Inverse/Secondary/Hover"
    case surfaceMainButtonDestructiveOutlinedPrimaryDisabled = "Surface/MainButton/Destructive/Outlined/Primary/Disabled"
    case surfaceMainButtonDestructiveOutlinedPrimaryEnabled = "Surface/MainButton/Destructive/Outlined/Primary/Enabled"
    case surfaceMainButtonDestructiveOutlinedPrimaryHover = "Surface/MainButton/Destructive/Outlined/Primary/Hover"
    case surfaceMainButtonDestructiveOutlinedSecondaryDisabled = "Surface/MainButton/Destructive/Outlined/Secondary/Disabled"
    case surfaceMainButtonDestructiveOutlinedSecondaryEnabled = "Surface/MainButton/Destructive/Outlined/Secondary/Enabled"
    case surfaceMainButtonDestructiveOutlinedSecondaryHover = "Surface/MainButton/Destructive/Outlined/Secondary/Hover"
    case surfaceMediaImageBroken = "Surface/Media/Image/Broken"
    case surfaceMediaImageLoaded = "Surface/Media/Image/Loaded"
    case surfaceMediaImageLoading = "Surface/Media/Image/Loading"
    case surfaceMediaOverlayTransparentBlack = "Surface/Media/Overlay/TransparentBlack"
    case surfaceMediaOverlayTransparentWhite = "Surface/Media/Overlay/TransparentWhite"
    case surfaceMediaVideoBroken = "Surface/Media/Video/Broken"
    case surfaceMediaVideoLoaded = "Surface/Media/Video/Loaded"
    case surfaceMediaVideoLoading = "Surface/Media/Video/Loading"
    case surfaceMenuListActive = "Surface/MenuList/Active"
    case surfaceMenuListDefault = "Surface/MenuList/Default"
    case surfaceMenuListHover = "Surface/MenuList/Hover"
    case surfacePageBackgroundDefault = "Surface/Page/Background/Default"
    case surfacePopoverBackgroundDefault = "Surface/Popover/Background/Default"
    case surfacePopoverListsDefault = "Surface/Popover/Lists/Default"
    case surfacePopoverListsDisabled = "Surface/Popover/Lists/Disabled"
    case surfacePopoverListsHover = "Surface/Popover/Lists/Hover"
    case surfaceProgressBarEmpty = "Surface/Progress/Bar/Empty"
    case surfaceProgressBarFilled = "Surface/Progress/Bar/Filled"
    case surfaceProgressKnobDefault = "Surface/Progress/Knob/Default"
    case surfaceReactionsReactionCountActive = "Surface/Reactions/ReactionCount/Active"
    case surfaceReactionsReactionCountDefault = "Surface/Reactions/ReactionCount/Default"
    case surfaceReactionsReactionPopoverFilledDefault = "Surface/Reactions/ReactionPopover/Filled/Default"
    case surfaceReactionsReactionPopoverReactionNameActive = "Surface/Reactions/ReactionPopover/ReactionName/Active"
    case surfaceReactionsReactionPopoverReactionStateActive = "Surface/Reactions/ReactionPopover/ReactionState/Active"
    case surfaceReactionsReactionPopoverTransparentDefault = "Surface/Reactions/ReactionPopover/Transparent/Default"
    case surfaceSelectionCheckboxAtomicActiveDefault = "Surface/Selection/CheckboxAtomic/Active/Default"
    case surfaceSelectionCheckboxAtomicActiveDisabled = "Surface/Selection/CheckboxAtomic/Active/Disabled"
    case surfaceSelectionCheckboxAtomicInactiveDefault = "Surface/Selection/CheckboxAtomic/Inactive/Default"
    case surfaceSelectionCheckboxAtomicInactiveDisabled = "Surface/Selection/CheckboxAtomic/Inactive/Disabled"
    case surfaceSelectionRadioAtomicActiveDefault = "Surface/Selection/RadioAtomic/Active/Default"
    case surfaceSelectionRadioAtomicActiveDisabled = "Surface/Selection/RadioAtomic/Active/Disabled"
    case surfaceSelectionRadioAtomicInactiveDefault = "Surface/Selection/RadioAtomic/Inactive/Default"
    case surfaceSelectionRadioAtomicInactiveDisabled = "Surface/Selection/RadioAtomic/Inactive/Disabled"
    case surfaceSheetsBackgroundGeneral = "Surface/Sheets/Background/General"
    case surfaceSheetsHandleDefault = "Surface/Sheets/Handle/Default"
    case surfaceSideNavigationBackgroundDefault = "Surface/SideNavigation/Background/Default"
    case surfaceSkeletonEffectDefault = "Surface/SkeletonEffect/Default"
    case surfaceSquareButtonDefaultPrimaryDefault = "Surface/SquareButton/Default/Primary/Default"
    case surfaceSquareButtonDefaultPrimaryDisabled = "Surface/SquareButton/Default/Primary/Disabled"
    case surfaceSquareButtonDefaultPrimaryHover = "Surface/SquareButton/Default/Primary/Hover"
    case surfaceSquareButtonDefaultSecondaryDefault = "Surface/SquareButton/Default/Secondary/Default"
    case surfaceSquareButtonDefaultSecondaryDisabled = "Surface/SquareButton/Default/Secondary/Disabled"
    case surfaceSquareButtonDefaultSecondaryHover = "Surface/SquareButton/Default/Secondary/Hover"
    case surfaceSquareButtonDestructiveDefault = "Surface/SquareButton/Destructive/Default"
    case surfaceSquareButtonDestructiveDisabled = "Surface/SquareButton/Destructive/Disabled"
    case surfaceSquareButtonDestructiveHover = "Surface/SquareButton/Destructive/Hover"
    case surfaceTabPillActive = "Surface/Tab/Pill/Active"
    case surfaceTabPillDefault = "Surface/Tab/Pill/Default"
    case surfaceTabPillDisabled = "Surface/Tab/Pill/Disabled"
    case surfaceTabPillHover = "Surface/Tab/Pill/Hover"
    case surfaceTabPillPress = "Surface/Tab/Pill/Press"
    case surfaceToggleBackgroundActiveDisabled = "Surface/Toggle/Background/Active/Disabled"
    case surfaceToggleBackgroundActiveEnabled = "Surface/Toggle/Background/Active/Enabled"
    case surfaceToggleBackgroundActiveFocused = "Surface/Toggle/Background/Active/Focused"
    case surfaceToggleBackgroundActiveHovered = "Surface/Toggle/Background/Active/Hovered"
    case surfaceToggleBackgroundActivePressed = "Surface/Toggle/Background/Active/Pressed"
    case surfaceToggleBackgroundInactiveDisabled = "Surface/Toggle/Background/Inactive/Disabled"
    case surfaceToggleBackgroundInactiveEnabled = "Surface/Toggle/Background/Inactive/Enabled"
    case surfaceToggleBackgroundInactiveFocused = "Surface/Toggle/Background/Inactive/Focused"
    case surfaceToggleBackgroundInactiveHovered = "Surface/Toggle/Background/Inactive/Hovered"
    case surfaceToggleBackgroundInactivePressed = "Surface/Toggle/Background/Inactive/Pressed"
    case surfaceToggleThumbActiveDisabled = "Surface/Toggle/Thumb/Active/Disabled"
    case surfaceToggleThumbActiveEnabled = "Surface/Toggle/Thumb/Active/Enabled"
    case surfaceToggleThumbActiveFocused = "Surface/Toggle/Thumb/Active/Focused"
    case surfaceToggleThumbActiveHovered = "Surface/Toggle/Thumb/Active/Hovered"
    case surfaceToggleThumbActivePressed = "Surface/Toggle/Thumb/Active/Pressed"
    case surfaceToggleThumbInactiveDisabled = "Surface/Toggle/Thumb/Inactive/Disabled"
    case surfaceToggleThumbInactiveEnabled = "Surface/Toggle/Thumb/Inactive/Enabled"
    case surfaceToggleThumbInactiveFocused = "Surface/Toggle/Thumb/Inactive/Focused"
    case surfaceToggleThumbInactiveHovered = "Surface/Toggle/Thumb/Inactive/Hovered"
    case surfaceToggleThumbInactivePressed = "Surface/Toggle/Thumb/Inactive/Pressed"
    case surfaceTopNavigationBackgroundDefault = "Surface/TopNavigation/Background/Default"
    case textAlertDialogBodyDefault = "Text/AlertDialog/Body/Default"
    case textAlertDialogHeaderTextDescriptionDefault = "Text/AlertDialog/Header/TextDescription/Default"
    case textAlertDialogHeaderTitleDefault = "Text/AlertDialog/Header/Title/Default"
    case textAvatarAtomicGeneral = "Text/Avatar/Atomic/General"
    case textAvatarLabelDefault = "Text/Avatar/Label/Default"
    case textBadgeAtomicBadgeDefault = "Text/Badge/AtomicBadge/Default"
    case textBadgeAtomicBadgeInverse = "Text/Badge/AtomicBadge/Inverse"
    case textBadgeSemanticBadgeChatArchivedDefault = "Text/Badge/SemanticBadge/Chat/Archived/Default"
    case textBadgeSemanticBadgeEventGeneralDefault = "Text/Badge/SemanticBadge/Event/General/Default"
    case textBadgeSemanticBadgeEventHostDefault = "Text/Badge/SemanticBadge/Event/Host/Default"
    case textBadgeSemanticBadgeGeneralDefaultDefault = "Text/Badge/SemanticBadge/General/Default/Default"
    case textBadgeSemanticBadgeLiveGeneralDefault = "Text/Badge/SemanticBadge/Live/General/Default"
    case textBadgeSemanticBadgePostStatusFeaturedDefault = "Text/Badge/SemanticBadge/PostStatus/Featured/Default"
    case textBadgeSemanticBadgePostStatusSponsoredDefault = "Text/Badge/SemanticBadge/PostStatus/Sponsored/Default"
    case textBadgeSemanticBadgePostStatusTotalMediaGeneral = "Text/Badge/SemanticBadge/PostStatus/TotalMedia/General"
    case textBadgeSemanticBadgeUserStatusModeratorDefault = "Text/Badge/SemanticBadge/UserStatus/Moderator/Default"
    case textBannerDefaultHeaderGeneral = "Text/Banner/Default/Header/General"
    case textBannerDefaultOverlineGeneral = "Text/Banner/Default/Overline/General"
    case textBannerDefaultSubheadGeneral = "Text/Banner/Default/Subhead/General"
    case textBannerDefaultTextDescriptionGeneral = "Text/Banner/Default/TextDescription/General"
    case textBannerDefaultTrailingSubtextGeneral = "Text/Banner/Default/Trailing/Subtext/General"
    case textBannerDefaultTrailingTextGeneral = "Text/Banner/Default/Trailing/Text/General"
    case textBannerSubdueHeaderGeneral = "Text/Banner/Subdue/Header/General"
    case textBannerSubdueOverlineGeneral = "Text/Banner/Subdue/Overline/General"
    case textBannerSubdueSubheadGeneral = "Text/Banner/Subdue/Subhead/General"
    case textBannerSubdueTextDescriptionGeneral = "Text/Banner/Subdue/TextDescription/General"
    case textBannerSubdueTrailingSubtextGeneral = "Text/Banner/Subdue/Trailing/Subtext/General"
    case textBannerSubdueTrailingTextGeneral = "Text/Banner/Subdue/Trailing/Text/General"
    case textBaseAlert = "Text/Base/Alert"
    case textBaseDefault = "Text/Base/Default"
    case textBaseDisabled = "Text/Base/Disabled"
    case textBaseHighlight = "Text/Base/Highlight"
    case textBaseInverse = "Text/Base/Inverse"
    case textBaseSubdue = "Text/Base/Subdue"
    case textCardPreviewLinkDomainDefault = "Text/Card/PreviewLink/Domain/Default"
    case textCardPreviewLinkTitleDefault = "Text/Card/PreviewLink/Title/Default"
    case textChatBubbleInboundEditedLabelDefault = "Text/ChatBubble/Inbound/EditedLabel/Default"
    case textChatBubbleInboundHeaderRepliedToDefault = "Text/ChatBubble/Inbound/Header/RepliedTo/Default"
    case textChatBubbleInboundHeaderUserNameDefault = "Text/ChatBubble/Inbound/Header/UserName/Default"
    case textChatBubbleInboundLinkDefault = "Text/ChatBubble/Inbound/Link/Default"
    case textChatBubbleInboundMentionedDefault = "Text/ChatBubble/Inbound/Mentioned/Default"
    case textChatBubbleInboundMessagesDefault = "Text/ChatBubble/Inbound/Messages/Default"
    case textChatBubbleInboundMessagesDeleted = "Text/ChatBubble/Inbound/Messages/Deleted"
    case textChatBubbleInboundSeeMoreDefault = "Text/ChatBubble/Inbound/SeeMore/Default"
    case textChatBubbleOutboundEditedLabelDefault = "Text/ChatBubble/Outbound/EditedLabel/Default"
    case textChatBubbleOutboundHeaderRepliedToDefault = "Text/ChatBubble/Outbound/Header/RepliedTo/Default"
    case textChatBubbleOutboundHeaderUserNameDefault = "Text/ChatBubble/Outbound/Header/UserName/Default"
    case textChatBubbleOutboundHelperTextDefault = "Text/ChatBubble/Outbound/Helper text/Default"
    case textChatBubbleOutboundLinkDefault = "Text/ChatBubble/Outbound/Link/Default"
    case textChatBubbleOutboundMentionedDefault = "Text/ChatBubble/Outbound/Mentioned/Default"
    case textChatBubbleOutboundMessagesDefault = "Text/ChatBubble/Outbound/Messages/Default"
    case textChatBubbleOutboundMessagesDeleted = "Text/ChatBubble/Outbound/Messages/Deleted"
    case textChatBubbleOutboundSeeMoreDefault = "Text/ChatBubble/Outbound/SeeMore/Default"
    case textChatBubbleTimestampSendingDefault = "Text/ChatBubble/Timestamp/Sending/Default"
    case textChatBubbleTimestampSentDefault = "Text/ChatBubble/Timestamp/Sent/Default"
    case textChipsFilledDefault = "Text/Chips/Filled/Default"
    case textChipsFilledDisabled = "Text/Chips/Filled/Disabled"
    case textChipsOutlinedDefault = "Text/Chips/Outlined/Default"
    case textChipsOutlinedDisabled = "Text/Chips/Outlined/Disabled"
    case textCustomToastDefault = "Text/CustomToast/Default"
    case textDateAndTimeDateSeparatorDefault = "Text/Date&Time/DateSeparator/Default"
    case textDividerDefault = "Text/Divider/Default"
    case textEmptyStateDescriptionDefault = "Text/EmptyState/Description/Default"
    case textEmptyStateTitleDefault = "Text/EmptyState/Title/Default"
    case textIconButtonLabelGeneral = "Text/IconButton/Label/General"
    case textInputChipInputHintTextDefault = "Text/Input/ChipInput/HintText/Default"
    case textInputChipInputHintTextError = "Text/Input/ChipInput/HintText/Error"
    case textInputChipInputIndicatorDefault = "Text/Input/ChipInput/Indicator/Default"
    case textInputChipInputIndicatorDisabled = "Text/Input/ChipInput/Indicator/Disabled"
    case textInputChipInputIndicatorError = "Text/Input/ChipInput/Indicator/Error"
    case textInputChipInputPlaceholderDisabled = "Text/Input/ChipInput/Placeholder/Disabled"
    case textInputChipInputPlaceholderEnabled = "Text/Input/ChipInput/Placeholder/Enabled"
    case textInputChipInputPlaceholderError = "Text/Input/ChipInput/Placeholder/Error"
    case textInputChipInputTextCountDefault = "Text/Input/ChipInput/TextCount/Default"
    case textInputChipInputTextCursorDefault = "Text/Input/ChipInput/TextCursor/Default"
    case textInputChipInputTextDescriptionDefault = "Text/Input/ChipInput/TextDescription/Default"
    case textInputChipInputTextDescriptionDisabled = "Text/Input/ChipInput/TextDescription/Disabled"
    case textInputChipInputTextDescriptionError = "Text/Input/ChipInput/TextDescription/Error"
    case textInputChipInputTitleDefault = "Text/Input/ChipInput/Title/Default"
    case textInputChipInputTitleDisabled = "Text/Input/ChipInput/Title/Disabled"
    case textInputChipInputTitleError = "Text/Input/ChipInput/Title/Error"
    case textInputTextInputHintTextDefault = "Text/Input/TextInput/HintText/Default"
    case textInputTextInputHintTextError = "Text/Input/TextInput/HintText/Error"
    case textInputTextInputIndicatorDefault = "Text/Input/TextInput/Indicator/Default"
    case textInputTextInputPlaceholderDisabled = "Text/Input/TextInput/Placeholder/Disabled"
    case textInputTextInputPlaceholderDisabledFilled = "Text/Input/TextInput/Placeholder/Disabled-Filled"
    case textInputTextInputPlaceholderDisabledHighlight = "Text/Input/TextInput/Placeholder/Disabled-Highlight"
    case textInputTextInputPlaceholderEnabled = "Text/Input/TextInput/Placeholder/Enabled"
    case textInputTextInputPlaceholderEnabledFilled = "Text/Input/TextInput/Placeholder/Enabled-Filled"
    case textInputTextInputPlaceholderEnabledHighlight = "Text/Input/TextInput/Placeholder/Enabled-Highlight"
    case textInputTextInputPlaceholderError = "Text/Input/TextInput/Placeholder/Error"
    case textInputTextInputPlaceholderErrorFilled = "Text/Input/TextInput/Placeholder/Error-Filled"
    case textInputTextInputPlaceholderErrorHighlight = "Text/Input/TextInput/Placeholder/Error-Highlight"
    case textInputTextInputPlaceholderFocused = "Text/Input/TextInput/Placeholder/Focused"
    case textInputTextInputPlaceholderFocusedFilled = "Text/Input/TextInput/Placeholder/Focused-Filled"
    case textInputTextInputPlaceholderFocusedHighlight = "Text/Input/TextInput/Placeholder/Focused-Highlight"
    case textInputTextInputTextCountDefault = "Text/Input/TextInput/TextCount/Default"
    case textInputTextInputTextCursorDefault = "Text/Input/TextInput/TextCursor/Default"
    case textInputTextInputTextDescriptionDefault = "Text/Input/TextInput/TextDescription/Default"
    case textInputTextInputTitleDefault = "Text/Input/TextInput/Title/Default"
    case textInputUserInputActionDefault = "Text/Input/UserInput/Action/Default"
    case textInputUserInputActionDisabled = "Text/Input/UserInput/Action/Disabled"
    case textInputUserInputIndicatorDefault = "Text/Input/UserInput/Indicator/Default"
    case textInputUserInputIndicatorDisabled = "Text/Input/UserInput/Indicator/Disabled"
    case textInputUserInputTextDescriptionDefault = "Text/Input/UserInput/TextDescription/Default"
    case textInputUserInputTextDescriptionDisabled = "Text/Input/UserInput/TextDescription/Disabled"
    case textInputUserInputTitleDefault = "Text/Input/UserInput/Title/Default"
    case textInputUserInputTitleDisabled = "Text/Input/UserInput/Title/Disabled"
    case textInputUserInputUserNameDefault = "Text/Input/UserInput/UserName/Default"
    case textInputUserInputUserNameDisabled = "Text/Input/UserInput/UserName/Disabled"
    case textListHeaderDefaultDefault = "Text/List/Header/Default/Default"
    case textListHeaderDefaultDisabled = "Text/List/Header/Default/Disabled"
    case textListHeaderDefaultHighlight = "Text/List/Header/Default/Highlight"
    case textListHeaderDefaultHover = "Text/List/Header/Default/Hover"
    case textListHeaderDestructiveDefault = "Text/List/Header/Destructive/Default"
    case textListHeaderDestructiveDisabled = "Text/List/Header/Destructive/Disabled"
    case textListHeaderDestructiveHover = "Text/List/Header/Destructive/Hover"
    case textListLabelActive = "Text/List/Label/Active"
    case textListLabelDefault = "Text/List/Label/Default"
    case textListLabelDisabled = "Text/List/Label/Disabled"
    case textListLabelHover = "Text/List/Label/Hover"
    case textListOverlineDefaultDefault = "Text/List/Overline/Default/Default"
    case textListSubheadDefaultDefault = "Text/List/Subhead/Default/Default"
    case textListSubheadDefaultDisabled = "Text/List/Subhead/Default/Disabled"
    case textListSubheadDefaultHighlight = "Text/List/Subhead/Default/Highlight"
    case textListSubheadDefaultHover = "Text/List/Subhead/Default/Hover"
    case textListSubheadDestructiveDefault = "Text/List/Subhead/Destructive/Default"
    case textListSubheadDestructiveDisabled = "Text/List/Subhead/Destructive/Disabled"
    case textListSubheadDestructiveHover = "Text/List/Subhead/Destructive/Hover"
    case textListTextDescriptionDefaultDefault = "Text/List/TextDescription/Default/Default"
    case textListTextDescriptionDefaultDisabled = "Text/List/TextDescription/Default/Disabled"
    case textListTextDescriptionDefaultHighlight = "Text/List/TextDescription/Default/Highlight"
    case textListTextDescriptionDefaultHover = "Text/List/TextDescription/Default/Hover"
    case textListTextDescriptionDestructiveDefault = "Text/List/TextDescription/Destructive/Default"
    case textListTextDescriptionDestructiveDisabled = "Text/List/TextDescription/Destructive/Disabled"
    case textListTextDescriptionDestructiveHover = "Text/List/TextDescription/Destructive/Hover"
    case textListTrailingSubtextDefault = "Text/List/Trailing/Subtext/Default"
    case textListTrailingTextGeneral = "Text/List/Trailing/Text/General"
    case textLoadersUploadControllerDefault = "Text/Loaders/UploadController/Default"
    case textMainButtonDefaultDescriptionPrimaryDisabled = "Text/MainButton/Default/Description/Primary/Disabled"
    case textMainButtonDefaultDescriptionPrimaryEnabled = "Text/MainButton/Default/Description/Primary/Enabled"
    case textMainButtonDefaultDescriptionPrimaryHover = "Text/MainButton/Default/Description/Primary/Hover"
    case textMainButtonDefaultDescriptionSecondaryDisabled = "Text/MainButton/Default/Description/Secondary/Disabled"
    case textMainButtonDefaultDescriptionSecondaryEnabled = "Text/MainButton/Default/Description/Secondary/Enabled"
    case textMainButtonDefaultDescriptionSecondaryHover = "Text/MainButton/Default/Description/Secondary/Hover"
    case textMainButtonDefaultFilledPrimaryDisabled = "Text/MainButton/Default/Filled/Primary/Disabled"
    case textMainButtonDefaultFilledPrimaryEnabled = "Text/MainButton/Default/Filled/Primary/Enabled"
    case textMainButtonDefaultFilledPrimaryHover = "Text/MainButton/Default/Filled/Primary/Hover"
    case textMainButtonDefaultFilledSecondaryDisabled = "Text/MainButton/Default/Filled/Secondary/Disabled"
    case textMainButtonDefaultFilledSecondaryEnabled = "Text/MainButton/Default/Filled/Secondary/Enabled"
    case textMainButtonDefaultFilledSecondaryHover = "Text/MainButton/Default/Filled/Secondary/Hover"
    case textMainButtonDefaultGhostPrimaryDisabled = "Text/MainButton/Default/Ghost/Primary/Disabled"
    case textMainButtonDefaultGhostPrimaryEnabled = "Text/MainButton/Default/Ghost/Primary/Enabled"
    case textMainButtonDefaultGhostPrimaryHover = "Text/MainButton/Default/Ghost/Primary/Hover"
    case textMainButtonDefaultGhostSecondaryDisabled = "Text/MainButton/Default/Ghost/Secondary/Disabled"
    case textMainButtonDefaultGhostSecondaryEnabled = "Text/MainButton/Default/Ghost/Secondary/Enabled"
    case textMainButtonDefaultGhostSecondaryHover = "Text/MainButton/Default/Ghost/Secondary/Hover"
    case textMainButtonDefaultInversePrimaryDisabled = "Text/MainButton/Default/Inverse/Primary/Disabled"
    case textMainButtonDefaultInversePrimaryEnabled = "Text/MainButton/Default/Inverse/Primary/Enabled"
    case textMainButtonDefaultInversePrimaryHover = "Text/MainButton/Default/Inverse/Primary/Hover"
    case textMainButtonDefaultInverseSecondaryDisabled = "Text/MainButton/Default/Inverse/Secondary/Disabled"
    case textMainButtonDefaultInverseSecondaryEnabled = "Text/MainButton/Default/Inverse/Secondary/Enabled"
    case textMainButtonDefaultInverseSecondaryHover = "Text/MainButton/Default/Inverse/Secondary/Hover"
    case textMainButtonDefaultLinkPrimaryDisabled = "Text/MainButton/Default/Link/Primary/Disabled"
    case textMainButtonDefaultLinkPrimaryEnabled = "Text/MainButton/Default/Link/Primary/Enabled"
    case textMainButtonDefaultLinkPrimaryHover = "Text/MainButton/Default/Link/Primary/Hover"
    case textMainButtonDefaultLinkSecondaryDisabled = "Text/MainButton/Default/Link/Secondary/Disabled"
    case textMainButtonDefaultLinkSecondaryEnabled = "Text/MainButton/Default/Link/Secondary/Enabled"
    case textMainButtonDefaultLinkSecondaryHover = "Text/MainButton/Default/Link/Secondary/Hover"
    case textMainButtonDefaultOutlinedPrimaryDisabled = "Text/MainButton/Default/Outlined/Primary/Disabled"
    case textMainButtonDefaultOutlinedPrimaryEnabled = "Text/MainButton/Default/Outlined/Primary/Enabled"
    case textMainButtonDefaultOutlinedPrimaryHover = "Text/MainButton/Default/Outlined/Primary/Hover"
    case textMainButtonDefaultOutlinedSecondaryDisabled = "Text/MainButton/Default/Outlined/Secondary/Disabled"
    case textMainButtonDefaultOutlinedSecondaryEnabled = "Text/MainButton/Default/Outlined/Secondary/Enabled"
    case textMainButtonDefaultOutlinedSecondaryHover = "Text/MainButton/Default/Outlined/Secondary/Hover"
    case textMainButtonDefaultTransparentPrimaryDisabled = "Text/MainButton/Default/Transparent/Primary/Disabled"
    case textMainButtonDefaultTransparentPrimaryEnabled = "Text/MainButton/Default/Transparent/Primary/Enabled"
    case textMainButtonDefaultTransparentPrimaryHover = "Text/MainButton/Default/Transparent/Primary/Hover"
    case textMainButtonDestructiveDescriptionPrimaryDisabled = "Text/MainButton/Destructive/Description/Primary/Disabled"
    case textMainButtonDestructiveDescriptionPrimaryEnabled = "Text/MainButton/Destructive/Description/Primary/Enabled"
    case textMainButtonDestructiveDescriptionPrimaryHover = "Text/MainButton/Destructive/Description/Primary/Hover"
    case textMainButtonDestructiveDescriptionSecondaryDisabled = "Text/MainButton/Destructive/Description/Secondary/Disabled"
    case textMainButtonDestructiveDescriptionSecondaryEnabled = "Text/MainButton/Destructive/Description/Secondary/Enabled"
    case textMainButtonDestructiveDescriptionSecondaryHover = "Text/MainButton/Destructive/Description/Secondary/Hover"
    case textMainButtonDestructiveFilledPrimaryDisabled = "Text/MainButton/Destructive/Filled/Primary/Disabled"
    case textMainButtonDestructiveFilledPrimaryEnabled = "Text/MainButton/Destructive/Filled/Primary/Enabled"
    case textMainButtonDestructiveFilledPrimaryHover = "Text/MainButton/Destructive/Filled/Primary/Hover"
    case textMainButtonDestructiveFilledSecondaryDisabled = "Text/MainButton/Destructive/Filled/Secondary/Disabled"
    case textMainButtonDestructiveFilledSecondaryEnabled = "Text/MainButton/Destructive/Filled/Secondary/Enabled"
    case textMainButtonDestructiveFilledSecondaryHover = "Text/MainButton/Destructive/Filled/Secondary/Hover"
    case textMainButtonDestructiveGhostPrimaryDisabled = "Text/MainButton/Destructive/Ghost/Primary/Disabled"
    case textMainButtonDestructiveGhostPrimaryEnabled = "Text/MainButton/Destructive/Ghost/Primary/Enabled"
    case textMainButtonDestructiveGhostPrimaryHover = "Text/MainButton/Destructive/Ghost/Primary/Hover"
    case textMainButtonDestructiveGhostSecondaryDisabled = "Text/MainButton/Destructive/Ghost/Secondary/Disabled"
    case textMainButtonDestructiveGhostSecondaryEnabled = "Text/MainButton/Destructive/Ghost/Secondary/Enabled"
    case textMainButtonDestructiveGhostSecondaryHover = "Text/MainButton/Destructive/Ghost/Secondary/Hover"
    case textMainButtonDestructiveInversePrimaryDisabled = "Text/MainButton/Destructive/Inverse/Primary/Disabled"
    case textMainButtonDestructiveInversePrimaryEnabled = "Text/MainButton/Destructive/Inverse/Primary/Enabled"
    case textMainButtonDestructiveInversePrimaryHover = "Text/MainButton/Destructive/Inverse/Primary/Hover"
    case textMainButtonDestructiveInverseSecondaryDisabled = "Text/MainButton/Destructive/Inverse/Secondary/Disabled"
    case textMainButtonDestructiveInverseSecondaryEnabled = "Text/MainButton/Destructive/Inverse/Secondary/Enabled"
    case textMainButtonDestructiveInverseSecondaryHover = "Text/MainButton/Destructive/Inverse/Secondary/Hover"
    case textMainButtonDestructiveLinkPrimaryDisabled = "Text/MainButton/Destructive/Link/Primary/Disabled"
    case textMainButtonDestructiveLinkPrimaryEnabled = "Text/MainButton/Destructive/Link/Primary/Enabled"
    case textMainButtonDestructiveLinkPrimaryHover = "Text/MainButton/Destructive/Link/Primary/Hover"
    case textMainButtonDestructiveLinkSecondaryDisabled = "Text/MainButton/Destructive/Link/Secondary/Disabled"
    case textMainButtonDestructiveLinkSecondaryEnabled = "Text/MainButton/Destructive/Link/Secondary/Enabled"
    case textMainButtonDestructiveLinkSecondaryHover = "Text/MainButton/Destructive/Link/Secondary/Hover"
    case textMainButtonDestructiveOutlinedPrimaryDisabled = "Text/MainButton/Destructive/Outlined/Primary/Disabled"
    case textMainButtonDestructiveOutlinedPrimaryEnabled = "Text/MainButton/Destructive/Outlined/Primary/Enabled"
    case textMainButtonDestructiveOutlinedPrimaryHover = "Text/MainButton/Destructive/Outlined/Primary/Hover"
    case textMainButtonDestructiveOutlinedSecondaryDisabled = "Text/MainButton/Destructive/Outlined/Secondary/Disabled"
    case textMainButtonDestructiveOutlinedSecondaryEnabled = "Text/MainButton/Destructive/Outlined/Secondary/Enabled"
    case textMainButtonDestructiveOutlinedSecondaryHover = "Text/MainButton/Destructive/Outlined/Secondary/Hover"
    case textMenuListActive = "Text/MenuList/Active"
    case textMenuListDefault = "Text/MenuList/Default"
    case textMenuListHover = "Text/MenuList/Hover"
    case textModalTextDescriptionDefault = "Text/Modal/TextDescription/Default"
    case textModalTitleDefault = "Text/Modal/Title/Default"
    case textReactionsChatReactionCountActive = "Text/Reactions/Chat/ReactionCount/Active"
    case textReactionsChatReactionCountDefault = "Text/Reactions/Chat/ReactionCount/Default"
    case textReactionsPostCommentCountGeneral = "Text/Reactions/Post/CommentCount/General"
    case textReactionsPostReactionCountGeneral = "Text/Reactions/Post/ReactionCount/General"
    case textReactionsReactionPopoverReactionNameGeneral = "Text/Reactions/ReactionPopover/ReactionName/General"
    case textSheetsHeaderTextDescriptionDefault = "Text/Sheets/Header/TextDescription/Default"
    case textSheetsHeaderTitleDefault = "Text/Sheets/Header/Title/Default"
    case textSquareButtonDefaultPrimaryDefault = "Text/SquareButton/Default/Primary/Default"
    case textSquareButtonDefaultPrimaryDisabled = "Text/SquareButton/Default/Primary/Disabled"
    case textSquareButtonDefaultPrimaryHover = "Text/SquareButton/Default/Primary/Hover"
    case textSquareButtonDefaultSecondaryDefault = "Text/SquareButton/Default/Secondary/Default"
    case textSquareButtonDefaultSecondaryDisabled = "Text/SquareButton/Default/Secondary/Disabled"
    case textSquareButtonDefaultSecondaryHover = "Text/SquareButton/Default/Secondary/Hover"
    case textSquareButtonDestructiveDefault = "Text/SquareButton/Destructive/Default"
    case textSquareButtonDestructiveDisabled = "Text/SquareButton/Destructive/Disabled"
    case textSquareButtonDestructiveHover = "Text/SquareButton/Destructive/Hover"
    case textTabPillActive = "Text/Tab/Pill/Active"
    case textTabPillDefault = "Text/Tab/Pill/Default"
    case textTabPillDisabled = "Text/Tab/Pill/Disabled"
    case textTabPillHover = "Text/Tab/Pill/Hover"
    case textTabPillPress = "Text/Tab/Pill/Press"
    case textTabUnderlinedActive = "Text/Tab/Underlined/Active"
    case textTabUnderlinedDefault = "Text/Tab/Underlined/Default"
    case textTabUnderlinedDisabled = "Text/Tab/Underlined/Disabled"
    case textTabUnderlinedHover = "Text/Tab/Underlined/Hover"
    case textTabUnderlinedPress = "Text/Tab/Underlined/Press"
    case textTimestampDefault = "Text/Timestamp/Default"
    case textTopNavigationDescription = "Text/TopNavigation/Description"
    case textTopNavigationFeedback = "Text/TopNavigation/Feedback"
    case textTopNavigationTitle = "Text/TopNavigation/Title"
}

extension AmityColorToken {
    /// The light & dark values this token resolves to.
    var values: (light: AmityColorTokenValue, dark: AmityColorTokenValue) {
        switch self {
        case .borderAvatarIndicatorDefault: return (.alias(.secondaryWhite), .alias(.backgroundStandardBlackDefault))
        case .borderAvatarProfileDefault: return (.alias(.secondaryWhite), .alias(.backgroundStandardBlackDefault))
        case .borderBadgeAtomicBadgeDefault: return (.alias(.secondaryWhite), .alias(.informationWhite))
        case .borderBadgeLiveStatusLiveDefault: return (.alias(.secondaryWhite), .alias(.informationWhite))
        case .borderBadgeSemanticBadgeGeneralDefault: return (.alias(.secondaryWhite), .alias(.informationWhite))
        case .borderChatBubbleInboundDefault: return (.alias(.secondaryWhite), .alias(.backgroundStandardBlackDefault))
        case .borderChatBubbleInboundDeleted: return (.alias(.secondary250), .alias(.secondary700))
        case .borderChatBubbleInboundPressed: return (.alias(.secondaryWhite), .alias(.backgroundStandardBlackDefault))
        case .borderChatBubbleOutboundDefault: return (.alias(.secondaryWhite), .alias(.backgroundStandardBlackDefault))
        case .borderChatBubbleOutboundDeleted: return (.alias(.primary500), .alias(.primary500))
        case .borderChipsFilledDisabled: return (.alias(.information200), .alias(.secondary700))
        case .borderChipsFilledEnabled: return (.alias(.information200), .alias(.secondaryWhite))
        case .borderChipsOutlinedDisabled: return (.alias(.information200), .alias(.secondary700))
        case .borderChipsOutlinedEnabled: return (.alias(.information200), .alias(.secondaryWhite))
        case .borderInputBoxedInputError: return (.alias(.signalAlert500), .alias(.signalAlert500))
        case .borderMainButtonDefaultFilledPrimaryDisabled: return (.alias(.primary200), .alias(.secondary800))
        case .borderMainButtonDefaultFilledPrimaryEnabled: return (.alias(.primary500), .alias(.primary500))
        case .borderMainButtonDefaultFilledPrimaryHover: return (.alias(.primary400), .alias(.primary400))
        case .borderMainButtonDefaultFilledSecondaryDisabled: return (.alias(.secondary200), .alias(.secondary800))
        case .borderMainButtonDefaultFilledSecondaryEnabled: return (.alias(.secondary200), .alias(.secondary700))
        case .borderMainButtonDefaultFilledSecondaryHover: return (.alias(.secondary400), .alias(.secondary400))
        case .borderMainButtonDefaultGhostPrimaryHover: return (.alias(.primary200), .alias(.primary800))
        case .borderMainButtonDefaultGhostSecondaryHover: return (.alias(.secondary200), .alias(.secondary800))
        case .borderMainButtonDefaultInversePrimaryDisabled: return (.alias(.backgroundTransparentBlack200), .alias(.backgroundTransparentBlack200))
        case .borderMainButtonDefaultInversePrimaryEnabled: return (.alias(.backgroundTransparentWhite0), .alias(.backgroundTransparentWhite0))
        case .borderMainButtonDefaultInversePrimaryHover: return (.alias(.backgroundTransparentBlack200), .alias(.backgroundTransparentWhite100))
        case .borderMainButtonDefaultInverseSecondaryDisabled: return (.alias(.backgroundTransparentBlack200), .alias(.backgroundTransparentBlack300))
        case .borderMainButtonDefaultInverseSecondaryEnabled: return (.alias(.backgroundTransparentWhite0), .alias(.backgroundTransparentWhite0))
        case .borderMainButtonDefaultInverseSecondaryHover: return (.alias(.backgroundTransparentWhite200), .alias(.backgroundTransparentWhite200))
        case .borderMainButtonDefaultOutlinedPrimaryDisabled: return (.alias(.primary200), .alias(.secondary800))
        case .borderMainButtonDefaultOutlinedPrimaryEnabled: return (.alias(.primary500), .alias(.primary500))
        case .borderMainButtonDefaultOutlinedPrimaryHover: return (.alias(.primary400), .alias(.primary400))
        case .borderMainButtonDefaultOutlinedSecondaryDisabled: return (.alias(.secondary400), .alias(.secondary800))
        case .borderMainButtonDefaultOutlinedSecondaryEnabled: return (.alias(.secondary400), .alias(.secondary500))
        case .borderMainButtonDefaultOutlinedSecondaryHover: return (.alias(.secondary400), .alias(.secondary500))
        case .borderMainButtonDefaultTransparentPrimaryDisabled: return (.alias(.backgroundTransparentBlack500), .alias(.backgroundTransparentBlack500))
        case .borderMainButtonDefaultTransparentPrimaryEnabled: return (.alias(.backgroundTransparentBlack500), .alias(.backgroundTransparentBlack500))
        case .borderMainButtonDefaultTransparentPrimaryHover: return (.alias(.backgroundTransparentBlack800), .alias(.backgroundTransparentBlack800))
        case .borderMainButtonDestructiveFilledPrimaryDisabled: return (.alias(.signalDestructive200), .alias(.secondary800))
        case .borderMainButtonDestructiveFilledPrimaryEnabled: return (.alias(.signalDestructive500), .alias(.signalDestructive700))
        case .borderMainButtonDestructiveFilledPrimaryHover: return (.alias(.signalDestructive300), .alias(.signalDestructive500))
        case .borderMainButtonDestructiveFilledSecondaryDisabled: return (.alias(.secondary200), .alias(.secondary800))
        case .borderMainButtonDestructiveFilledSecondaryEnabled: return (.alias(.secondary200), .alias(.secondary700))
        case .borderMainButtonDestructiveFilledSecondaryHover: return (.alias(.secondary400), .alias(.secondary400))
        case .borderMainButtonDestructiveGhostPrimaryHover: return (.alias(.signalDestructive200), .alias(.signalDestructive800))
        case .borderMainButtonDestructiveGhostSecondaryHover: return (.alias(.secondary200), .alias(.secondary800))
        case .borderMainButtonDestructiveInversePrimaryDisabled: return (.alias(.backgroundTransparentBlack200), .alias(.backgroundTransparentBlack200))
        case .borderMainButtonDestructiveInversePrimaryEnabled: return (.alias(.backgroundTransparentWhite0), .alias(.backgroundTransparentWhite0))
        case .borderMainButtonDestructiveInversePrimaryHover: return (.alias(.backgroundTransparentBlack200), .alias(.backgroundTransparentBlack200))
        case .borderMainButtonDestructiveInverseSecondaryDisabled: return (.alias(.backgroundTransparentBlack200), .alias(.backgroundTransparentBlack200))
        case .borderMainButtonDestructiveInverseSecondaryEnabled: return (.alias(.backgroundTransparentWhite0), .alias(.backgroundTransparentWhite0))
        case .borderMainButtonDestructiveInverseSecondaryHover: return (.alias(.backgroundTransparentRed200), .alias(.backgroundTransparentRed200))
        case .borderMainButtonDestructiveOutlinedPrimaryDisabled: return (.alias(.signalDestructive200), .alias(.secondary800))
        case .borderMainButtonDestructiveOutlinedPrimaryEnabled: return (.alias(.signalDestructive500), .alias(.signalDestructive700))
        case .borderMainButtonDestructiveOutlinedPrimaryHover: return (.alias(.signalDestructive300), .alias(.signalDestructive500))
        case .borderMainButtonDestructiveOutlinedSecondaryDisabled: return (.alias(.secondary400), .alias(.secondary800))
        case .borderMainButtonDestructiveOutlinedSecondaryEnabled: return (.alias(.secondary400), .alias(.secondary500))
        case .borderMainButtonDestructiveOutlinedSecondaryHover: return (.alias(.secondary400), .alias(.secondary500))
        case .borderReactionReactionAtomDefault: return (.alias(.backgroundStandardWhiteDefault), .alias(.backgroundStandardBlackDefault))
        case .borderReactionReactionCountActive: return (.alias(.secondary200), .alias(.secondary700))
        case .borderReactionReactionCountDefault: return (.alias(.secondary200), .alias(.secondary700))
        case .borderSelectionCheckboxAtomicInactiveDefault: return (.alias(.secondary400), .alias(.secondaryWhite))
        case .borderSelectionCheckboxAtomicInactiveDisabled: return (.alias(.secondary200), .alias(.secondary700))
        case .borderSelectionRadioAtomicInactiveDefault: return (.alias(.secondary400), .alias(.secondaryWhite))
        case .borderSelectionRadioAtomicInactiveDisabled: return (.alias(.secondary200), .alias(.secondary700))
        case .borderSideNavigationDefault: return (.alias(.secondary200), .hex("#FFFFFF"))
        case .borderTabPillActive: return (.alias(.primary500), .alias(.primary500))
        case .borderTabPillDefault: return (.alias(.secondary200), .alias(.secondary700))
        case .borderTabPillDisabled: return (.alias(.secondary200), .alias(.secondary700))
        case .borderTabPillHover: return (.alias(.secondary200), .alias(.secondary700))
        case .borderTabPillPress: return (.alias(.secondary200), .alias(.secondary700))
        case .borderToggleBackgroundActiveDisabled: return (.alias(.primary200), .alias(.primary800))
        case .borderToggleBackgroundActiveEnabled: return (.alias(.primary500), .alias(.primary400))
        case .borderToggleBackgroundActiveFocused: return (.alias(.primary500), .alias(.primary400))
        case .borderToggleBackgroundActiveHovered: return (.alias(.primary500), .alias(.primary400))
        case .borderToggleBackgroundActivePressed: return (.alias(.primary500), .alias(.primary400))
        case .borderToggleBackgroundInactiveDisabled: return (.alias(.secondary200), .alias(.secondary800))
        case .borderToggleBackgroundInactiveEnabled: return (.alias(.secondary400), .alias(.secondary500))
        case .borderToggleBackgroundInactiveFocused: return (.alias(.secondary400), .alias(.secondary500))
        case .borderToggleBackgroundInactiveHovered: return (.alias(.secondary400), .alias(.secondary500))
        case .borderToggleBackgroundInactivePressed: return (.alias(.secondary400), .alias(.secondary500))
        case .borderToggleThumbActiveFocused: return (.hex("#00000033"), .hex("#00000033"))
        case .borderToggleThumbActiveHovered: return (.hex("#0000001A"), .hex("#0000001A"))
        case .borderToggleThumbActivePressed: return (.hex("#00000033"), .hex("#00000033"))
        case .borderToggleThumbInactiveFocused: return (.hex("#00000033"), .hex("#00000033"))
        case .borderToggleThumbInactiveHovered: return (.hex("#0000001A"), .hex("#0000001A"))
        case .borderToggleThumbInactivePressed: return (.hex("#00000033"), .hex("#00000033"))
        case .iconActionButtonSplitButtonDefault: return (.alias(.secondary800), .alias(.secondaryWhite))
        case .iconActionButtonSplitButtonDisabled: return (.alias(.secondary300), .alias(.secondary500))
        case .iconActionButtonSplitButtonHover: return (.alias(.secondary800), .alias(.secondaryWhite))
        case .iconAvatarDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconBadgeAtomicBadgeDefault: return (.alias(.information800), .alias(.informationWhite))
        case .iconBadgeAtomicBadgeInverse: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconBadgeDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconBadgeSemanticBadgeChatArchivedDefault: return (.alias(.secondary700), .alias(.informationWhite))
        case .iconBadgeSemanticBadgeChatMentionDefault: return (.alias(.primary500), .alias(.primary200))
        case .iconBadgeSemanticBadgeChatPrivateDefault: return (.alias(.primary500), .alias(.primary200))
        case .iconBadgeSemanticBadgeCommunityGeneralDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconBadgeSemanticBadgeCommunityOfficialDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconBadgeSemanticBadgeCommunityPrivateDefault: return (.alias(.information800), .alias(.informationWhite))
        case .iconBadgeSemanticBadgeEventHostDefault: return (.alias(.signalEvent500), .alias(.signalEvent500))
        case .iconBadgeSemanticBadgeLiveAlertDefault: return (.alias(.signalLive500), .alias(.informationWhite))
        case .iconBadgeSemanticBadgeLiveGeneralDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconBadgeSemanticBadgePostStatusSponsoredDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconBadgeSemanticBadgeUserStatusBannedDefault: return (.alias(.information500), .alias(.informationWhite))
        case .iconBadgeSemanticBadgeUserStatusBrandDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconBadgeSemanticBadgeUserStatusModeratorDefault: return (.alias(.primary600), .alias(.informationWhite))
        case .iconBadgeSemanticBadgeUserStatusMutedDefault: return (.alias(.information500), .alias(.informationWhite))
        case .iconBadgeSemanticBadgeUserStatusPrivateDefault: return (.alias(.information800), .alias(.informationWhite))
        case .iconBannerDefaultDescriptionGeneral: return (.alias(.secondary700), .alias(.secondary500))
        case .iconBannerDefaultLeadingIconGeneral: return (.alias(.information800), .alias(.secondaryWhite))
        case .iconBannerDefaultTrailingIconGeneral: return (.alias(.information800), .alias(.secondaryWhite))
        case .iconBannerSubdueDescriptionGeneral: return (.alias(.secondary400), .alias(.secondary500))
        case .iconBannerSubdueLeadingIconGeneral: return (.alias(.information800), .alias(.secondaryWhite))
        case .iconBannerSubdueTrailingIconGeneral: return (.alias(.information800), .alias(.secondaryWhite))
        case .iconChatBubbleInboundHeaderRepliedToDefault: return (.alias(.information800), .alias(.information200))
        case .iconChatBubbleInboundMessagesDeleted: return (.alias(.information500), .alias(.information500))
        case .iconChatBubbleInboundSeeMoreDefault: return (.alias(.information500), .alias(.information500))
        case .iconChatBubbleOutboundDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconChatBubbleOutboundHeaderRepliedToDefault: return (.alias(.information800), .alias(.information200))
        case .iconChatBubbleOutboundMessagesDeleted: return (.alias(.primary500), .alias(.primary400))
        case .iconChatBubbleOutboundSeeMoreDefault: return (.alias(.primary250), .alias(.primary250))
        case .iconCustomToastDefault: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconEmptyStateIconDefault: return (.alias(.secondary200), .alias(.secondary700))
        case .iconFeaturedIconSolid: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconFeaturedIconTinted: return (.alias(.secondary800), .alias(.secondaryWhite))
        case .iconFloatingButtonDefault: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconGeneralDefault: return (.alias(.secondary800), .alias(.secondary800))
        case .iconGeneralInverse: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconIconButtonFilledPrimaryDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconIconButtonFilledPrimaryDisabled: return (.alias(.informationWhite), .alias(.primary700))
        case .iconIconButtonFilledPrimaryHovered: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconIconButtonFilledSecondaryDefault: return (.alias(.information700), .alias(.informationWhite))
        case .iconIconButtonFilledSecondaryDisabled: return (.alias(.information300), .alias(.information700))
        case .iconIconButtonFilledSecondaryHovered: return (.alias(.information700), .alias(.informationWhite))
        case .iconIconButtonGhostPrimaryDefault: return (.alias(.primary600), .alias(.primary500))
        case .iconIconButtonGhostPrimaryDisabled: return (.alias(.primary250), .alias(.primary700))
        case .iconIconButtonGhostPrimaryHovered: return (.alias(.primary600), .alias(.primary400))
        case .iconIconButtonGhostSecondaryDefault: return (.alias(.information800), .alias(.informationWhite))
        case .iconIconButtonGhostSecondaryDisabled: return (.alias(.information300), .alias(.information700))
        case .iconIconButtonGhostSecondaryHovered: return (.alias(.information800), .alias(.informationWhite))
        case .iconIconButtonTransparentPrimaryDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconIconButtonTransparentPrimaryDisabled: return (.alias(.information300), .alias(.information700))
        case .iconIconButtonTransparentPrimaryHovered: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconInputChipInputDefault: return (.alias(.secondary400), .alias(.secondary500))
        case .iconInputChipInputDisabled: return (.alias(.secondary300), .alias(.secondary700))
        case .iconInputChipInputError: return (.alias(.secondary400), .alias(.secondary500))
        case .iconInputTextInputDefault: return (.alias(.secondary400), .alias(.secondary500))
        case .iconInputTextInputDisabled: return (.alias(.secondary300), .alias(.secondary700))
        case .iconInputTextInputError: return (.alias(.secondary400), .alias(.secondary500))
        case .iconListDescriptionGeneral: return (.alias(.secondary400), .alias(.secondary500))
        case .iconListHeaderGeneral: return (.alias(.secondary400), .alias(.secondary500))
        case .iconListLeadingActive: return (.alias(.information800), .alias(.secondaryWhite))
        case .iconListLeadingDefaultActive: return (.alias(.information800), .alias(.secondaryWhite))
        case .iconListLeadingDefaultDefault: return (.alias(.information800), .alias(.secondaryWhite))
        case .iconListLeadingDefaultDisabled: return (.alias(.information500), .alias(.secondary700))
        case .iconListLeadingDefaultHover: return (.alias(.information800), .alias(.secondaryWhite))
        case .iconListLeadingDestructiveDefault: return (.alias(.signalDestructive500), .alias(.signalDestructive400))
        case .iconListLeadingDestructiveDisabled: return (.alias(.signalDestructive200), .alias(.signalDestructive800))
        case .iconListLeadingDestructiveHover: return (.alias(.signalDestructive500), .alias(.signalDestructive400))
        case .iconListLeadingDisabled: return (.alias(.information500), .alias(.secondary700))
        case .iconListLeadingHover: return (.alias(.information800), .alias(.secondaryWhite))
        case .iconLoadersRefresherGeneral: return (.alias(.secondary800), .alias(.secondary200))
        case .iconLoadersUploadControllerDefault: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconMainButtonDefaultDescriptionPrimaryDisabled: return (.alias(.primary250), .alias(.secondary500))
        case .iconMainButtonDefaultDescriptionPrimaryEnabled: return (.alias(.primary500), .alias(.primary250))
        case .iconMainButtonDefaultDescriptionPrimaryHover: return (.alias(.primary400), .alias(.primary200))
        case .iconMainButtonDefaultDescriptionSecondaryDisabled: return (.alias(.secondary300), .alias(.secondary500))
        case .iconMainButtonDefaultDescriptionSecondaryEnabled: return (.alias(.secondary800), .alias(.secondary200))
        case .iconMainButtonDefaultDescriptionSecondaryHover: return (.alias(.secondary700), .alias(.secondary200))
        case .iconMainButtonDefaultFilledPrimaryDisabled: return (.alias(.secondaryWhite), .alias(.secondary500))
        case .iconMainButtonDefaultFilledPrimaryEnabled: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconMainButtonDefaultFilledPrimaryHover: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconMainButtonDefaultFilledSecondaryDisabled: return (.alias(.secondary500), .alias(.secondary500))
        case .iconMainButtonDefaultFilledSecondaryEnabled: return (.alias(.secondary800), .alias(.secondaryWhite))
        case .iconMainButtonDefaultFilledSecondaryHover: return (.alias(.secondary800), .alias(.secondaryWhite))
        case .iconMainButtonDefaultGhostPrimaryDisabled: return (.alias(.primary250), .alias(.secondary500))
        case .iconMainButtonDefaultGhostPrimaryEnabled: return (.alias(.primary500), .alias(.primary400))
        case .iconMainButtonDefaultGhostPrimaryHover: return (.alias(.primary500), .alias(.primary200))
        case .iconMainButtonDefaultGhostSecondaryDisabled: return (.alias(.secondary500), .alias(.secondary500))
        case .iconMainButtonDefaultGhostSecondaryEnabled: return (.alias(.secondary800), .alias(.secondary200))
        case .iconMainButtonDefaultGhostSecondaryHover: return (.alias(.secondary800), .alias(.secondary200))
        case .iconMainButtonDefaultInversePrimaryDisabled: return (.alias(.secondary800), .alias(.secondary500))
        case .iconMainButtonDefaultInversePrimaryEnabled: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconMainButtonDefaultInversePrimaryHover: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconMainButtonDefaultInverseSecondaryDisabled: return (.alias(.secondary700), .alias(.secondary500))
        case .iconMainButtonDefaultInverseSecondaryEnabled: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconMainButtonDefaultInverseSecondaryHover: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconMainButtonDefaultLinkPrimaryDisabled: return (.alias(.primary250), .alias(.secondary500))
        case .iconMainButtonDefaultLinkPrimaryEnabled: return (.alias(.primary500), .alias(.primary250))
        case .iconMainButtonDefaultLinkPrimaryHover: return (.alias(.primary400), .alias(.primary200))
        case .iconMainButtonDefaultLinkSecondaryDisabled: return (.alias(.secondary300), .alias(.secondary500))
        case .iconMainButtonDefaultLinkSecondaryEnabled: return (.alias(.secondary800), .alias(.secondary200))
        case .iconMainButtonDefaultLinkSecondaryHover: return (.alias(.secondary700), .alias(.secondary200))
        case .iconMainButtonDefaultOutlinedPrimaryDisabled: return (.alias(.primary250), .alias(.secondary500))
        case .iconMainButtonDefaultOutlinedPrimaryEnabled: return (.alias(.primary500), .alias(.primary250))
        case .iconMainButtonDefaultOutlinedPrimaryHover: return (.alias(.primary400), .alias(.primary200))
        case .iconMainButtonDefaultOutlinedSecondaryDisabled: return (.alias(.secondary300), .alias(.secondary500))
        case .iconMainButtonDefaultOutlinedSecondaryEnabled: return (.alias(.secondary800), .alias(.secondary200))
        case .iconMainButtonDefaultOutlinedSecondaryHover: return (.alias(.secondary800), .alias(.secondary200))
        case .iconMainButtonDefaultTransparentPrimaryDisabled: return (.alias(.secondary300), .alias(.secondary500))
        case .iconMainButtonDefaultTransparentPrimaryEnabled: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconMainButtonDefaultTransparentPrimaryHover: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconMainButtonDestructiveDescriptionPrimaryDisabled: return (.alias(.signalDestructive200), .alias(.secondary500))
        case .iconMainButtonDestructiveDescriptionPrimaryEnabled: return (.alias(.signalDestructive500), .alias(.signalDestructive500))
        case .iconMainButtonDestructiveDescriptionPrimaryHover: return (.alias(.signalDestructive300), .alias(.signalDestructive200))
        case .iconMainButtonDestructiveDescriptionSecondaryDisabled: return (.alias(.secondary300), .alias(.secondary500))
        case .iconMainButtonDestructiveDescriptionSecondaryEnabled: return (.alias(.secondary800), .alias(.secondaryWhite))
        case .iconMainButtonDestructiveDescriptionSecondaryHover: return (.alias(.secondary700), .alias(.secondaryWhite))
        case .iconMainButtonDestructiveFilledPrimaryDisabled: return (.alias(.secondaryWhite), .alias(.secondary500))
        case .iconMainButtonDestructiveFilledPrimaryEnabled: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconMainButtonDestructiveFilledPrimaryHover: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconMainButtonDestructiveFilledSecondaryDisabled: return (.alias(.secondary500), .alias(.secondary500))
        case .iconMainButtonDestructiveFilledSecondaryEnabled: return (.alias(.secondary800), .alias(.secondaryWhite))
        case .iconMainButtonDestructiveFilledSecondaryHover: return (.alias(.secondary800), .alias(.secondaryWhite))
        case .iconMainButtonDestructiveGhostPrimaryDisabled: return (.alias(.signalDestructive200), .alias(.secondary500))
        case .iconMainButtonDestructiveGhostPrimaryEnabled: return (.alias(.signalDestructive500), .alias(.signalDestructive400))
        case .iconMainButtonDestructiveGhostPrimaryHover: return (.alias(.signalDestructive500), .alias(.signalDestructive200))
        case .iconMainButtonDestructiveGhostSecondaryDisabled: return (.alias(.secondary500), .alias(.secondary500))
        case .iconMainButtonDestructiveGhostSecondaryEnabled: return (.alias(.secondary800), .alias(.secondaryWhite))
        case .iconMainButtonDestructiveGhostSecondaryHover: return (.alias(.secondary800), .alias(.secondaryWhite))
        case .iconMainButtonDestructiveInversePrimaryDisabled: return (.alias(.secondary700), .alias(.secondary500))
        case .iconMainButtonDestructiveInversePrimaryEnabled: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconMainButtonDestructiveInversePrimaryHover: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconMainButtonDestructiveInverseSecondaryDisabled: return (.alias(.secondary700), .alias(.secondary500))
        case .iconMainButtonDestructiveInverseSecondaryEnabled: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconMainButtonDestructiveInverseSecondaryHover: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconMainButtonDestructiveLinkPrimaryDisabled: return (.alias(.signalDestructive200), .alias(.secondary500))
        case .iconMainButtonDestructiveLinkPrimaryEnabled: return (.alias(.signalDestructive500), .alias(.signalDestructive400))
        case .iconMainButtonDestructiveLinkPrimaryHover: return (.alias(.signalDestructive300), .alias(.signalDestructive200))
        case .iconMainButtonDestructiveLinkSecondaryDisabled: return (.alias(.secondary300), .alias(.secondary500))
        case .iconMainButtonDestructiveLinkSecondaryEnabled: return (.alias(.secondary800), .alias(.secondaryWhite))
        case .iconMainButtonDestructiveLinkSecondaryHover: return (.alias(.secondary700), .alias(.secondaryWhite))
        case .iconMainButtonDestructiveOutlinedPrimaryDisabled: return (.alias(.signalDestructive300), .alias(.secondary500))
        case .iconMainButtonDestructiveOutlinedPrimaryEnabled: return (.alias(.signalDestructive500), .alias(.signalDestructive300))
        case .iconMainButtonDestructiveOutlinedPrimaryHover: return (.alias(.signalDestructive300), .alias(.signalDestructive200))
        case .iconMainButtonDestructiveOutlinedSecondaryDisabled: return (.alias(.secondary300), .alias(.secondary500))
        case .iconMainButtonDestructiveOutlinedSecondaryEnabled: return (.alias(.secondary800), .alias(.secondaryWhite))
        case .iconMainButtonDestructiveOutlinedSecondaryHover: return (.alias(.secondary800), .alias(.secondaryWhite))
        case .iconMediaImageBroken: return (.alias(.secondary400), .alias(.secondary500))
        case .iconMediaVideoBroken: return (.alias(.secondary400), .alias(.secondary500))
        case .iconSelectionCheckboxAtomicDefault: return (.alias(.informationWhite), .alias(.primaryWhite))
        case .iconSelectionCheckboxAtomicDisabled: return (.alias(.informationWhite), .alias(.primary700))
        case .iconSelectionRadioAtomicDefault: return (.alias(.informationWhite), .alias(.primaryWhite))
        case .iconSelectionRadioAtomicDisabled: return (.alias(.informationWhite), .alias(.primary700))
        case .iconSheetsDefaultDefault: return (.alias(.information500), .alias(.secondary800))
        case .iconSquareButtonDefaultPrimaryDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconSquareButtonDefaultPrimaryDisabled: return (.alias(.informationWhite), .alias(.information700))
        case .iconSquareButtonDefaultPrimaryHover: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconSquareButtonDefaultSecondaryDefault: return (.alias(.information800), .alias(.informationWhite))
        case .iconSquareButtonDefaultSecondaryDisabled: return (.alias(.information300), .alias(.information700))
        case .iconSquareButtonDefaultSecondaryHover: return (.alias(.information800), .alias(.informationWhite))
        case .iconSquareButtonDestructiveDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconSquareButtonDestructiveDisabled: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconSquareButtonDestructiveHover: return (.alias(.informationWhite), .alias(.informationWhite))
        case .iconTabActive: return (.alias(.secondary800), .alias(.secondary200))
        case .iconTabDefault: return (.alias(.secondary500), .alias(.secondary500))
        case .iconTabDisabled: return (.alias(.secondary300), .alias(.secondary700))
        case .iconTabHover: return (.alias(.secondary500), .alias(.secondary500))
        case .iconTabPress: return (.alias(.secondary500), .alias(.secondary500))
        case .iconToggleActiveGeneral: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .iconToggleInactiveGeneral: return (.alias(.secondary200), .alias(.secondary300))
        case .lineChatBubbleInboundDividerDefault: return (.alias(.secondary400), .alias(.secondary700))
        case .lineChatBubbleOutboundDividerDefault: return (.alias(.primary400), .alias(.primary400))
        case .lineCommentBubbleConnectorEndDefault: return (.alias(.secondary200), .alias(.primary500))
        case .lineCommentBubbleConnectorMiddleDefault: return (.alias(.secondary200), .alias(.primary500))
        case .lineCommentBubbleConnectorStartDefault: return (.alias(.secondary200), .alias(.primary500))
        case .lineDividerContentDefault: return (.alias(.secondary200), .alias(.secondary800))
        case .lineDividerPostDefault: return (.alias(.secondary200), .alias(.secondary700))
        case .lineInputChipInputUnderlinedDefault: return (.alias(.secondary200), .alias(.secondary200))
        case .lineInputChipInputUnderlinedDisabled: return (.alias(.secondary200), .alias(.secondary700))
        case .lineInputChipInputUnderlinedError: return (.alias(.signalAlert500), .alias(.signalAlert500))
        case .lineInputTextInputUnderlinedDefault: return (.alias(.secondary200), .alias(.secondary300))
        case .lineInputTextInputUnderlinedDisabled: return (.alias(.secondary200), .alias(.secondary700))
        case .lineInputTextInputUnderlinedError: return (.alias(.signalAlert500), .alias(.signalAlert500))
        case .lineTabIconActive: return (.alias(.primary500), .alias(.primary500))
        case .lineTabUnderlinedActive: return (.alias(.primary500), .alias(.primary400))
        case .surfaceActionButtonsCaptureButtonGeneral: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .surfaceActionButtonsHover: return (.alias(.secondary400), .hex("#FFFFFF"))
        case .surfaceActionButtonsPressed: return (.alias(.secondary200), .hex("#FFFFFF"))
        case .surfaceActionButtonsSplitButtonEnabled: return (.alias(.secondary200), .alias(.secondary800))
        case .surfaceActionButtonsSplitButtonHover: return (.alias(.secondary400), .alias(.secondary700))
        case .surfaceActionButtonsSplitButtonPressed: return (.alias(.secondary200), .alias(.secondary700))
        case .surfaceAlertDialogBackgroundDefault: return (.alias(.secondaryWhite), .alias(.secondary800))
        case .surfaceAvatarProfileDefault: return (.alias(.primary250), .alias(.primary400))
        case .surfaceBackgroundDefault: return (.alias(.backgroundWhiteDefault), .alias(.backgroundBlackDefault))
        case .surfaceBackgroundSubdue: return (.hex("#F5F5F5"), .hex("#242424"))
        case .surfaceBadgeAtomicBadgeFilledDefault: return (.alias(.primary500), .alias(.primary500))
        case .surfaceBadgeSemanticBadgeChatArchived: return (.alias(.secondary200), .alias(.secondary700))
        case .surfaceBadgeSemanticBadgeChatMention: return (.alias(.primary200), .alias(.primary500))
        case .surfaceBadgeSemanticBadgeChatPrivate: return (.alias(.primary200), .alias(.primary500))
        case .surfaceBadgeSemanticBadgeCommunityGeneral: return (.alias(.primary250), .alias(.primary500))
        case .surfaceBadgeSemanticBadgeCommunityOfficial: return (.alias(.primary600), .alias(.secondary700))
        case .surfaceBadgeSemanticBadgeEventDefault: return (.alias(.secondary700), .alias(.secondary700))
        case .surfaceBadgeSemanticBadgeEventHost: return (.alias(.signalEvent150), .alias(.signalEvent150))
        case .surfaceBadgeSemanticBadgeGeneralDot: return (.alias(.signalAlert500), .alias(.signalAlert700))
        case .surfaceBadgeSemanticBadgeGeneralDuration: return (.alias(.backgroundTransparentBlack600), .alias(.backgroundTransparentBlack600))
        case .surfaceBadgeSemanticBadgeGeneralNotification: return (.alias(.signalAlert500), .alias(.signalAlert700))
        case .surfaceBadgeSemanticBadgeGeneralSelection: return (.alias(.primary500), .alias(.primary500))
        case .surfaceBadgeSemanticBadgeLiveAlert: return (.alias(.signalLive500), .alias(.secondary700))
        case .surfaceBadgeSemanticBadgeLiveIndicator: return (.alias(.backgroundTransparentBlack200), .alias(.secondary700))
        case .surfaceBadgeSemanticBadgeLiveInformation: return (.alias(.secondary700), .alias(.secondary700))
        case .surfaceBadgeSemanticBadgePostStatusFeatured: return (.alias(.secondary200), .alias(.secondary700))
        case .surfaceBadgeSemanticBadgePostStatusSponsored: return (.alias(.backgroundTransparentBlack300), .alias(.backgroundTransparentBlack300))
        case .surfaceBadgeSemanticBadgePostStatusTotalMedia: return (.alias(.backgroundTransparentBlack500), .alias(.backgroundTransparentBlack500))
        case .surfaceBadgeSemanticBadgeUserStatusModerator: return (.alias(.primary200), .alias(.primary500))
        case .surfaceBannerDefaultGeneral: return (.alias(.secondaryWhite), .alias(.backgroundStandardBlackDefault))
        case .surfaceBannerSubdueGeneral: return (.alias(.secondary200), .alias(.secondary800))
        case .surfaceCardPreviewLinkDefault: return (.alias(.secondaryWhite), .alias(.secondary700))
        case .surfaceCardPreviewLinkSkeleton: return (.alias(.secondaryWhite), .alias(.secondary700))
        case .surfaceCardPreviewLinkUnavailable: return (.alias(.secondaryWhite), .alias(.secondary700))
        case .surfaceChatBubbleMessageInboundDefault: return (.alias(.secondary200), .alias(.secondary800))
        case .surfaceChatBubbleMessageInboundDeleted: return (.alias(.secondary200), .alias(.backgroundStandardBlackDefault))
        case .surfaceChatBubbleMessageInboundPressed: return (.alias(.secondary400), .alias(.secondary750))
        case .surfaceChatBubbleMessageOutboundDefault: return (.alias(.primary500), .alias(.primary500))
        case .surfaceChatBubbleMessageOutboundDeleted: return (.alias(.secondaryWhite), .alias(.backgroundStandardBlackDefault))
        case .surfaceChatBubbleMessageOutboundFailed: return (.alias(.primary500), .alias(.primary500))
        case .surfaceChatBubbleMessageOutboundPressed: return (.alias(.primary700), .alias(.primary700))
        case .surfaceChatBubbleReplyMessageDefault: return (.alias(.secondary200), .alias(.secondary800))
        case .surfaceChatBubbleReplyMessageFailed: return (.alias(.secondaryWhite), .alias(.blackBlack))
        case .surfaceChatBubbleReplyOverlayDefault: return (.alias(.backgroundTransparentWhite600), .alias(.backgroundTransparentBlack300))
        case .surfaceChipsFilledDefault: return (.alias(.secondary250), .alias(.secondary700))
        case .surfaceChipsFilledDisabled: return (.alias(.secondary250), .alias(.secondary800))
        case .surfaceChipsOutlinedDefault: return (.alias(.secondaryWhite), .alias(.secondary800))
        case .surfaceChipsOutlinedDisabled: return (.alias(.secondaryWhite), .alias(.secondary800))
        case .surfaceCustomToastDefaultDefault: return (.alias(.secondary750), .alias(.secondary750))
        case .surfaceDateAndTimeDateSeparatorDefault: return (.alias(.secondaryWhite), .alias(.secondary800))
        case .surfaceFeaturedIconSolid: return (.alias(.primary500), .alias(.primary500))
        case .surfaceFeaturedIconTinted: return (.alias(.secondary200), .alias(.secondary800))
        case .surfaceFloatingButtonEnabled: return (.alias(.primary600), .alias(.primary500))
        case .surfaceFloatingButtonHover: return (.alias(.primary400), .alias(.primary400))
        case .surfaceFloatingButtonPressed: return (.alias(.primary500), .alias(.primary700))
        case .surfaceIconButtonFilledPrimaryDisabled: return (.alias(.primary200), .alias(.primary800))
        case .surfaceIconButtonFilledPrimaryEnabled: return (.alias(.primary500), .alias(.primary500))
        case .surfaceIconButtonFilledPrimaryHover: return (.alias(.primary400), .alias(.primary400))
        case .surfaceIconButtonFilledSecondaryDisabled: return (.alias(.secondary200), .alias(.secondary800))
        case .surfaceIconButtonFilledSecondaryEnabled: return (.alias(.secondary200), .alias(.secondary700))
        case .surfaceIconButtonFilledSecondaryHover: return (.alias(.secondary400), .alias(.secondary500))
        case .surfaceIconButtonGhostPrimaryHover: return (.alias(.primary200), .alias(.primary800))
        case .surfaceIconButtonGhostSecondaryHover: return (.alias(.secondary200), .alias(.secondary800))
        case .surfaceIconButtonTransparentPrimaryDisabled: return (.alias(.backgroundTransparentBlack500), .alias(.backgroundTransparentBlack600))
        case .surfaceIconButtonTransparentPrimaryEnabled: return (.alias(.backgroundTransparentBlack500), .alias(.backgroundTransparentBlack600))
        case .surfaceIconButtonTransparentPrimaryHover: return (.alias(.backgroundTransparentBlack800), .alias(.backgroundTransparentBlack800))
        case .surfaceInputBoxedInputDefault: return (.alias(.secondary200), .alias(.secondary800))
        case .surfaceListDefaultActive: return (.alias(.primary200), .alias(.primary800))
        case .surfaceListDefaultDefault: return (.alias(.secondaryWhite), .alias(.backgroundStandardBlackDefault))
        case .surfaceListDefaultDisabled: return (.alias(.secondaryWhite), .alias(.backgroundStandardBlackDefault))
        case .surfaceListDefaultHover: return (.alias(.secondary200), .alias(.secondary800))
        case .surfaceListDestructiveDefault: return (.alias(.secondaryWhite), .alias(.backgroundStandardBlackDefault))
        case .surfaceListDestructiveDisabled: return (.alias(.secondaryWhite), .alias(.backgroundBlackDefault))
        case .surfaceListDestructiveHover: return (.alias(.secondary200), .alias(.backgroundStandardBlackSubdue))
        case .surfaceListSkeletonSkeleton: return (.alias(.secondaryWhite), .alias(.backgroundStandardBlackDefault))
        case .surfaceLoadersRefresherGeneral: return (.alias(.secondaryWhite), .alias(.secondary800))
        case .surfaceLoadersSpinnerBackground: return (.alias(.primaryWhite), .alias(.primaryWhite))
        case .surfaceLoadersSpinnerIcon: return (.alias(.primary600), .alias(.primary500))
        case .surfaceLoadersUploadControllerBackground: return (.alias(.backgroundTransparentWhite800), .alias(.backgroundTransparentWhite800))
        case .surfaceLoadersUploadControllerLoader: return (.alias(.secondaryWhite), .alias(.primaryWhite))
        case .surfaceMainButtonDefaultFilledPrimaryDisabled: return (.alias(.primary200), .alias(.secondary800))
        case .surfaceMainButtonDefaultFilledPrimaryEnabled: return (.alias(.primary500), .alias(.primary500))
        case .surfaceMainButtonDefaultFilledPrimaryHover: return (.alias(.primary400), .alias(.primary400))
        case .surfaceMainButtonDefaultFilledSecondaryDisabled: return (.alias(.secondary200), .alias(.secondary800))
        case .surfaceMainButtonDefaultFilledSecondaryEnabled: return (.alias(.secondary200), .alias(.secondary700))
        case .surfaceMainButtonDefaultFilledSecondaryHover: return (.alias(.secondary400), .alias(.secondary400))
        case .surfaceMainButtonDefaultGhostPrimaryHover: return (.alias(.primary200), .alias(.primary800))
        case .surfaceMainButtonDefaultGhostSecondaryHover: return (.alias(.secondary200), .alias(.secondary800))
        case .surfaceMainButtonDefaultInversePrimaryDisabled: return (.alias(.backgroundTransparentBlack200), .alias(.backgroundTransparentBlack200))
        case .surfaceMainButtonDefaultInversePrimaryEnabled: return (.alias(.backgroundTransparentWhite0), .alias(.backgroundTransparentWhite0))
        case .surfaceMainButtonDefaultInversePrimaryHover: return (.alias(.backgroundTransparentBlack200), .alias(.backgroundTransparentWhite100))
        case .surfaceMainButtonDefaultInverseSecondaryDisabled: return (.alias(.backgroundTransparentBlack200), .alias(.backgroundTransparentBlack300))
        case .surfaceMainButtonDefaultInverseSecondaryEnabled: return (.alias(.backgroundTransparentWhite0), .alias(.backgroundTransparentWhite0))
        case .surfaceMainButtonDefaultInverseSecondaryHover: return (.alias(.backgroundTransparentWhite200), .alias(.backgroundTransparentWhite200))
        case .surfaceMainButtonDefaultOutlinedPrimaryDisabled: return (.alias(.secondary200), .alias(.backgroundBlackDefault))
        case .surfaceMainButtonDefaultOutlinedPrimaryEnabled: return (.alias(.primaryWhite), .alias(.secondary800))
        case .surfaceMainButtonDefaultOutlinedPrimaryHover: return (.alias(.primaryWhite), .alias(.secondary800))
        case .surfaceMainButtonDefaultOutlinedSecondaryDisabled: return (.alias(.secondary200), .alias(.backgroundBlackDefault))
        case .surfaceMainButtonDefaultOutlinedSecondaryEnabled: return (.alias(.secondaryWhite), .alias(.secondary800))
        case .surfaceMainButtonDefaultOutlinedSecondaryHover: return (.alias(.secondaryWhite), .alias(.secondary800))
        case .surfaceMainButtonDefaultTransparentPrimaryDisabled: return (.alias(.backgroundTransparentBlack500), .alias(.backgroundTransparentBlack500))
        case .surfaceMainButtonDefaultTransparentPrimaryEnabled: return (.alias(.backgroundTransparentBlack500), .alias(.backgroundTransparentBlack500))
        case .surfaceMainButtonDefaultTransparentPrimaryHover: return (.alias(.backgroundTransparentBlack800), .alias(.backgroundTransparentBlack800))
        case .surfaceMainButtonDestructiveFilledPrimaryDisabled: return (.alias(.signalDestructive200), .alias(.secondary800))
        case .surfaceMainButtonDestructiveFilledPrimaryEnabled: return (.alias(.signalDestructive500), .alias(.signalDestructive700))
        case .surfaceMainButtonDestructiveFilledPrimaryHover: return (.alias(.signalDestructive300), .alias(.signalDestructive500))
        case .surfaceMainButtonDestructiveFilledSecondaryDisabled: return (.alias(.secondary200), .alias(.secondary800))
        case .surfaceMainButtonDestructiveFilledSecondaryEnabled: return (.alias(.secondary200), .alias(.secondary700))
        case .surfaceMainButtonDestructiveFilledSecondaryHover: return (.alias(.secondary400), .alias(.secondary400))
        case .surfaceMainButtonDestructiveGhostPrimaryHover: return (.alias(.signalDestructive200), .alias(.signalDestructive800))
        case .surfaceMainButtonDestructiveGhostSecondaryHover: return (.alias(.secondary200), .alias(.secondary800))
        case .surfaceMainButtonDestructiveInversePrimaryDisabled: return (.alias(.backgroundTransparentBlack200), .alias(.backgroundTransparentBlack200))
        case .surfaceMainButtonDestructiveInversePrimaryEnabled: return (.alias(.backgroundTransparentWhite0), .alias(.backgroundTransparentWhite0))
        case .surfaceMainButtonDestructiveInversePrimaryHover: return (.alias(.backgroundTransparentBlack200), .alias(.backgroundTransparentBlack200))
        case .surfaceMainButtonDestructiveInverseSecondaryDisabled: return (.alias(.backgroundTransparentBlack200), .alias(.backgroundTransparentBlack200))
        case .surfaceMainButtonDestructiveInverseSecondaryEnabled: return (.alias(.backgroundTransparentWhite0), .alias(.backgroundTransparentWhite0))
        case .surfaceMainButtonDestructiveInverseSecondaryHover: return (.alias(.backgroundTransparentRed200), .alias(.backgroundTransparentRed200))
        case .surfaceMainButtonDestructiveOutlinedPrimaryDisabled: return (.alias(.secondary200), .alias(.backgroundBlackDefault))
        case .surfaceMainButtonDestructiveOutlinedPrimaryEnabled: return (.alias(.primaryWhite), .alias(.secondary800))
        case .surfaceMainButtonDestructiveOutlinedPrimaryHover: return (.alias(.primaryWhite), .alias(.secondary800))
        case .surfaceMainButtonDestructiveOutlinedSecondaryDisabled: return (.alias(.secondary200), .alias(.backgroundBlackDefault))
        case .surfaceMainButtonDestructiveOutlinedSecondaryEnabled: return (.alias(.secondaryWhite), .alias(.backgroundBlackDefault))
        case .surfaceMainButtonDestructiveOutlinedSecondaryHover: return (.alias(.secondaryWhite), .alias(.backgroundBlackDefault))
        case .surfaceMediaImageBroken: return (.hex("#F5F5F5"), .alias(.secondary800))
        case .surfaceMediaImageLoaded: return (.hex("#F5F5F5"), .alias(.secondary800))
        case .surfaceMediaImageLoading: return (.hex("#F5F5F5"), .alias(.secondary800))
        case .surfaceMediaOverlayTransparentBlack: return (.alias(.backgroundTransparentBlack500), .alias(.backgroundTransparentBlack500))
        case .surfaceMediaOverlayTransparentWhite: return (.alias(.backgroundTransparentWhite600), .alias(.backgroundTransparentWhite600))
        case .surfaceMediaVideoBroken: return (.hex("#F5F5F5"), .alias(.secondary750))
        case .surfaceMediaVideoLoaded: return (.hex("#F5F5F5"), .alias(.secondary750))
        case .surfaceMediaVideoLoading: return (.hex("#F5F5F5"), .alias(.secondary750))
        case .surfaceMenuListActive: return (.alias(.primary250), .alias(.secondaryWhite))
        case .surfaceMenuListDefault: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .surfaceMenuListHover: return (.alias(.secondary200), .alias(.secondaryWhite))
        case .surfacePageBackgroundDefault: return (.alias(.backgroundStandardWhiteDefault), .alias(.backgroundStandardBlackDefault))
        case .surfacePopoverBackgroundDefault: return (.alias(.secondaryWhite), .alias(.secondary800))
        case .surfacePopoverListsDefault: return (.alias(.secondaryWhite), .alias(.secondary800))
        case .surfacePopoverListsDisabled: return (.alias(.secondaryWhite), .alias(.secondary800))
        case .surfacePopoverListsHover: return (.alias(.secondary200), .alias(.secondary700))
        case .surfaceProgressBarEmpty: return (.alias(.backgroundTransparentWhite300), .alias(.backgroundTransparentWhite300))
        case .surfaceProgressBarFilled: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .surfaceProgressKnobDefault: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .surfaceReactionsReactionCountActive: return (.alias(.primary500), .alias(.primary500))
        case .surfaceReactionsReactionCountDefault: return (.alias(.backgroundStandardWhiteDefault), .alias(.backgroundStandardBlackDefault))
        case .surfaceReactionsReactionPopoverFilledDefault: return (.alias(.secondaryWhite), .alias(.backgroundStandardBlackDefault))
        case .surfaceReactionsReactionPopoverReactionNameActive: return (.alias(.backgroundTransparentBlack500), .alias(.backgroundTransparentBlack500))
        case .surfaceReactionsReactionPopoverReactionStateActive: return (.alias(.secondary250), .alias(.secondary700))
        case .surfaceReactionsReactionPopoverTransparentDefault: return (.alias(.backgroundTransparentWhite400), .alias(.backgroundTransparentBlack500))
        case .surfaceSelectionCheckboxAtomicActiveDefault: return (.alias(.primary500), .alias(.primary500))
        case .surfaceSelectionCheckboxAtomicActiveDisabled: return (.alias(.primary200), .alias(.primary800))
        case .surfaceSelectionCheckboxAtomicInactiveDefault: return (.alias(.secondaryWhite), .alias(.backgroundBlackDefault))
        case .surfaceSelectionCheckboxAtomicInactiveDisabled: return (.alias(.secondaryWhite), .alias(.secondary800))
        case .surfaceSelectionRadioAtomicActiveDefault: return (.alias(.primary500), .alias(.primary500))
        case .surfaceSelectionRadioAtomicActiveDisabled: return (.alias(.primary200), .alias(.primary800))
        case .surfaceSelectionRadioAtomicInactiveDefault: return (.alias(.secondaryWhite), .alias(.backgroundBlackDefault))
        case .surfaceSelectionRadioAtomicInactiveDisabled: return (.alias(.secondaryWhite), .alias(.secondary800))
        case .surfaceSheetsBackgroundGeneral: return (.alias(.backgroundStandardWhiteDefault), .alias(.backgroundStandardBlackDefault))
        case .surfaceSheetsHandleDefault: return (.alias(.secondary500), .alias(.secondary500))
        case .surfaceSideNavigationBackgroundDefault: return (.alias(.secondaryWhite), .alias(.backgroundBlackDefault))
        case .surfaceSkeletonEffectDefault: return (.alias(.secondary200), .alias(.secondary500))
        case .surfaceSquareButtonDefaultPrimaryDefault: return (.alias(.primary500), .alias(.primary500))
        case .surfaceSquareButtonDefaultPrimaryDisabled: return (.alias(.primary200), .alias(.secondary800))
        case .surfaceSquareButtonDefaultPrimaryHover: return (.alias(.primary400), .alias(.primary600))
        case .surfaceSquareButtonDefaultSecondaryDefault: return (.alias(.secondary200), .alias(.secondary500))
        case .surfaceSquareButtonDefaultSecondaryDisabled: return (.alias(.secondary200), .alias(.secondary800))
        case .surfaceSquareButtonDefaultSecondaryHover: return (.alias(.secondary300), .alias(.secondary700))
        case .surfaceSquareButtonDestructiveDefault: return (.alias(.signalDestructive500), .alias(.signalDestructive700))
        case .surfaceSquareButtonDestructiveDisabled: return (.alias(.signalDestructive200), .alias(.secondary800))
        case .surfaceSquareButtonDestructiveHover: return (.alias(.signalDestructive300), .alias(.signalDestructive500))
        case .surfaceTabPillActive: return (.alias(.primary500), .alias(.primary500))
        case .surfaceTabPillDefault: return (.alias(.secondaryWhite), .alias(.backgroundStandardBlackDefault))
        case .surfaceTabPillDisabled: return (.alias(.secondaryWhite), .alias(.secondary800))
        case .surfaceTabPillHover: return (.alias(.secondaryWhite), .alias(.secondary800))
        case .surfaceTabPillPress: return (.alias(.secondary200), .alias(.secondary800))
        case .surfaceToggleBackgroundActiveDisabled: return (.alias(.primary200), .alias(.primary700))
        case .surfaceToggleBackgroundActiveEnabled: return (.alias(.primary500), .alias(.primary400))
        case .surfaceToggleBackgroundActiveFocused: return (.alias(.primary500), .alias(.primary400))
        case .surfaceToggleBackgroundActiveHovered: return (.alias(.primary500), .alias(.primary400))
        case .surfaceToggleBackgroundActivePressed: return (.alias(.primary500), .alias(.primary400))
        case .surfaceToggleBackgroundInactiveDisabled: return (.alias(.secondary200), .alias(.secondary800))
        case .surfaceToggleBackgroundInactiveEnabled: return (.alias(.secondary400), .alias(.secondary500))
        case .surfaceToggleBackgroundInactiveFocused: return (.alias(.secondary400), .alias(.secondary500))
        case .surfaceToggleBackgroundInactiveHovered: return (.alias(.secondary400), .alias(.secondary500))
        case .surfaceToggleBackgroundInactivePressed: return (.alias(.secondary400), .alias(.secondary500))
        case .surfaceToggleThumbActiveDisabled: return (.alias(.secondary200), .alias(.secondary500))
        case .surfaceToggleThumbActiveEnabled: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .surfaceToggleThumbActiveFocused: return (.alias(.secondary200), .alias(.secondaryWhite))
        case .surfaceToggleThumbActiveHovered: return (.alias(.secondary200), .alias(.secondaryWhite))
        case .surfaceToggleThumbActivePressed: return (.alias(.secondary200), .alias(.secondaryWhite))
        case .surfaceToggleThumbInactiveDisabled: return (.alias(.secondary500), .alias(.secondary700))
        case .surfaceToggleThumbInactiveEnabled: return (.alias(.secondaryWhite), .alias(.secondaryWhite))
        case .surfaceToggleThumbInactiveFocused: return (.alias(.secondary200), .alias(.secondaryWhite))
        case .surfaceToggleThumbInactiveHovered: return (.alias(.secondary200), .alias(.secondaryWhite))
        case .surfaceToggleThumbInactivePressed: return (.alias(.secondary200), .alias(.secondaryWhite))
        case .surfaceTopNavigationBackgroundDefault: return (.alias(.secondaryWhite), .alias(.backgroundBlackDefault))
        case .textAlertDialogBodyDefault: return (.alias(.information700), .alias(.informationWhite))
        case .textAlertDialogHeaderTextDescriptionDefault: return (.alias(.information500), .alias(.informationWhite))
        case .textAlertDialogHeaderTitleDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textAvatarAtomicGeneral: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textAvatarLabelDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textBadgeAtomicBadgeDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textBadgeAtomicBadgeInverse: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textBadgeSemanticBadgeChatArchivedDefault: return (.alias(.secondary700), .alias(.informationWhite))
        case .textBadgeSemanticBadgeEventGeneralDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textBadgeSemanticBadgeEventHostDefault: return (.alias(.signalEvent500), .alias(.signalEvent500))
        case .textBadgeSemanticBadgeGeneralDefaultDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textBadgeSemanticBadgeLiveGeneralDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textBadgeSemanticBadgePostStatusFeaturedDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textBadgeSemanticBadgePostStatusSponsoredDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textBadgeSemanticBadgePostStatusTotalMediaGeneral: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textBadgeSemanticBadgeUserStatusModeratorDefault: return (.alias(.primary600), .alias(.informationWhite))
        case .textBannerDefaultHeaderGeneral: return (.alias(.information800), .alias(.informationWhite))
        case .textBannerDefaultOverlineGeneral: return (.alias(.information800), .alias(.informationWhite))
        case .textBannerDefaultSubheadGeneral: return (.alias(.information500), .alias(.informationWhite))
        case .textBannerDefaultTextDescriptionGeneral: return (.alias(.information700), .alias(.information300))
        case .textBannerDefaultTrailingSubtextGeneral: return (.alias(.information500), .alias(.information300))
        case .textBannerDefaultTrailingTextGeneral: return (.alias(.information500), .alias(.information300))
        case .textBannerSubdueHeaderGeneral: return (.alias(.information800), .alias(.informationWhite))
        case .textBannerSubdueOverlineGeneral: return (.alias(.information800), .alias(.informationWhite))
        case .textBannerSubdueSubheadGeneral: return (.alias(.information500), .alias(.informationWhite))
        case .textBannerSubdueTextDescriptionGeneral: return (.alias(.information700), .alias(.information300))
        case .textBannerSubdueTrailingSubtextGeneral: return (.alias(.information500), .alias(.information300))
        case .textBannerSubdueTrailingTextGeneral: return (.alias(.information500), .alias(.information300))
        case .textBaseAlert: return (.alias(.signalAlert500), .alias(.signalAlert500))
        case .textBaseDefault: return (.alias(.information800), .alias(.information800))
        case .textBaseDisabled: return (.alias(.information500), .alias(.information500))
        case .textBaseHighlight: return (.alias(.primary500), .alias(.primary500))
        case .textBaseInverse: return (.alias(.genericWhiteWhite), .alias(.genericWhiteWhite))
        case .textBaseSubdue: return (.alias(.information700), .alias(.information700))
        case .textCardPreviewLinkDomainDefault: return (.alias(.information500), .alias(.information200))
        case .textCardPreviewLinkTitleDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textChatBubbleInboundEditedLabelDefault: return (.alias(.information700), .alias(.information200))
        case .textChatBubbleInboundHeaderRepliedToDefault: return (.alias(.information700), .alias(.information300))
        case .textChatBubbleInboundHeaderUserNameDefault: return (.alias(.information700), .alias(.information300))
        case .textChatBubbleInboundLinkDefault: return (.alias(.primary500), .alias(.primary250))
        case .textChatBubbleInboundMentionedDefault: return (.alias(.primary500), .alias(.primary250))
        case .textChatBubbleInboundMessagesDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textChatBubbleInboundMessagesDeleted: return (.alias(.information500), .alias(.information500))
        case .textChatBubbleInboundSeeMoreDefault: return (.alias(.information700), .alias(.information300))
        case .textChatBubbleOutboundEditedLabelDefault: return (.alias(.information200), .alias(.information200))
        case .textChatBubbleOutboundHeaderRepliedToDefault: return (.alias(.information700), .alias(.information300))
        case .textChatBubbleOutboundHeaderUserNameDefault: return (.alias(.information700), .alias(.information300))
        case .textChatBubbleOutboundHelperTextDefault: return (.alias(.signalAlert500), .alias(.signalAlert400))
        case .textChatBubbleOutboundLinkDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textChatBubbleOutboundMentionedDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textChatBubbleOutboundMessagesDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textChatBubbleOutboundMessagesDeleted: return (.alias(.primary500), .alias(.primary400))
        case .textChatBubbleOutboundSeeMoreDefault: return (.alias(.primary250), .alias(.primary250))
        case .textChatBubbleTimestampSendingDefault: return (.alias(.information500), .alias(.information500))
        case .textChatBubbleTimestampSentDefault: return (.alias(.information500), .alias(.information500))
        case .textChipsFilledDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textChipsFilledDisabled: return (.alias(.information500), .alias(.information700))
        case .textChipsOutlinedDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textChipsOutlinedDisabled: return (.alias(.information300), .alias(.information700))
        case .textCustomToastDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textDateAndTimeDateSeparatorDefault: return (.alias(.information700), .alias(.information300))
        case .textDividerDefault: return (.alias(.information500), .alias(.informationWhite))
        case .textEmptyStateDescriptionDefault: return (.alias(.information500), .alias(.information300))
        case .textEmptyStateTitleDefault: return (.alias(.information500), .alias(.information300))
        case .textIconButtonLabelGeneral: return (.alias(.information800), .alias(.informationWhite))
        case .textInputChipInputHintTextDefault: return (.alias(.information700), .alias(.informationWhite))
        case .textInputChipInputHintTextError: return (.alias(.signalAlert500), .alias(.signalAlert500))
        case .textInputChipInputIndicatorDefault: return (.alias(.information300), .alias(.informationWhite))
        case .textInputChipInputIndicatorDisabled: return (.alias(.information300), .alias(.informationWhite))
        case .textInputChipInputIndicatorError: return (.alias(.information300), .alias(.informationWhite))
        case .textInputChipInputPlaceholderDisabled: return (.alias(.information300), .alias(.information700))
        case .textInputChipInputPlaceholderEnabled: return (.alias(.information500), .alias(.informationWhite))
        case .textInputChipInputPlaceholderError: return (.alias(.information500), .alias(.informationWhite))
        case .textInputChipInputTextCountDefault: return (.alias(.information700), .alias(.informationWhite))
        case .textInputChipInputTextCursorDefault: return (.alias(.primary500), .alias(.informationWhite))
        case .textInputChipInputTextDescriptionDefault: return (.alias(.information700), .alias(.informationWhite))
        case .textInputChipInputTextDescriptionDisabled: return (.alias(.information700), .alias(.informationWhite))
        case .textInputChipInputTextDescriptionError: return (.alias(.information700), .alias(.informationWhite))
        case .textInputChipInputTitleDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textInputChipInputTitleDisabled: return (.alias(.information800), .alias(.informationWhite))
        case .textInputChipInputTitleError: return (.alias(.information800), .alias(.informationWhite))
        case .textInputTextInputHintTextDefault: return (.alias(.information700), .alias(.information500))
        case .textInputTextInputHintTextError: return (.alias(.signalAlert500), .alias(.signalAlert500))
        case .textInputTextInputIndicatorDefault: return (.alias(.information300), .alias(.information300))
        case .textInputTextInputPlaceholderDisabled: return (.alias(.information300), .alias(.information700))
        case .textInputTextInputPlaceholderDisabledFilled: return (.alias(.information300), .alias(.information700))
        case .textInputTextInputPlaceholderDisabledHighlight: return (.alias(.primary250), .alias(.primary250))
        case .textInputTextInputPlaceholderEnabled: return (.alias(.information500), .alias(.information500))
        case .textInputTextInputPlaceholderEnabledFilled: return (.alias(.information800), .alias(.informationWhite))
        case .textInputTextInputPlaceholderEnabledHighlight: return (.alias(.primary500), .alias(.primary400))
        case .textInputTextInputPlaceholderError: return (.alias(.information500), .alias(.information500))
        case .textInputTextInputPlaceholderErrorFilled: return (.alias(.information800), .alias(.informationWhite))
        case .textInputTextInputPlaceholderErrorHighlight: return (.alias(.primary500), .alias(.primary400))
        case .textInputTextInputPlaceholderFocused: return (.alias(.information500), .alias(.information500))
        case .textInputTextInputPlaceholderFocusedFilled: return (.alias(.information800), .alias(.informationWhite))
        case .textInputTextInputPlaceholderFocusedHighlight: return (.alias(.primary500), .alias(.primary400))
        case .textInputTextInputTextCountDefault: return (.alias(.information700), .alias(.information500))
        case .textInputTextInputTextCursorDefault: return (.alias(.primary500), .alias(.primary600))
        case .textInputTextInputTextDescriptionDefault: return (.alias(.information700), .alias(.information500))
        case .textInputTextInputTitleDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textInputUserInputActionDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textInputUserInputActionDisabled: return (.alias(.information500), .alias(.informationWhite))
        case .textInputUserInputIndicatorDefault: return (.alias(.information300), .alias(.informationWhite))
        case .textInputUserInputIndicatorDisabled: return (.alias(.information300), .alias(.informationWhite))
        case .textInputUserInputTextDescriptionDefault: return (.alias(.information700), .alias(.informationWhite))
        case .textInputUserInputTextDescriptionDisabled: return (.alias(.information700), .alias(.informationWhite))
        case .textInputUserInputTitleDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textInputUserInputTitleDisabled: return (.alias(.information800), .alias(.informationWhite))
        case .textInputUserInputUserNameDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textInputUserInputUserNameDisabled: return (.alias(.information800), .alias(.informationWhite))
        case .textListHeaderDefaultDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textListHeaderDefaultDisabled: return (.alias(.information500), .alias(.information700))
        case .textListHeaderDefaultHighlight: return (.alias(.primary500), .alias(.primary400))
        case .textListHeaderDefaultHover: return (.alias(.information800), .alias(.informationWhite))
        case .textListHeaderDestructiveDefault: return (.alias(.signalDestructive500), .alias(.signalDestructive400))
        case .textListHeaderDestructiveDisabled: return (.alias(.signalDestructive200), .alias(.signalDestructive800))
        case .textListHeaderDestructiveHover: return (.alias(.signalDestructive500), .alias(.signalDestructive400))
        case .textListLabelActive: return (.alias(.information700), .alias(.information300))
        case .textListLabelDefault: return (.alias(.information700), .alias(.information300))
        case .textListLabelDisabled: return (.alias(.information300), .alias(.information700))
        case .textListLabelHover: return (.alias(.information700), .alias(.information300))
        case .textListOverlineDefaultDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textListSubheadDefaultDefault: return (.alias(.information500), .alias(.informationWhite))
        case .textListSubheadDefaultDisabled: return (.alias(.information500), .alias(.informationWhite))
        case .textListSubheadDefaultHighlight: return (.alias(.information500), .alias(.informationWhite))
        case .textListSubheadDefaultHover: return (.alias(.information500), .alias(.informationWhite))
        case .textListSubheadDestructiveDefault: return (.alias(.signalDestructive500), .alias(.signalDestructive400))
        case .textListSubheadDestructiveDisabled: return (.alias(.signalDestructive200), .alias(.signalDestructive800))
        case .textListSubheadDestructiveHover: return (.alias(.signalDestructive500), .alias(.signalDestructive400))
        case .textListTextDescriptionDefaultDefault: return (.alias(.information700), .alias(.information300))
        case .textListTextDescriptionDefaultDisabled: return (.alias(.information300), .alias(.information700))
        case .textListTextDescriptionDefaultHighlight: return (.alias(.information700), .alias(.informationWhite))
        case .textListTextDescriptionDefaultHover: return (.alias(.information700), .alias(.information300))
        case .textListTextDescriptionDestructiveDefault: return (.alias(.information700), .alias(.information300))
        case .textListTextDescriptionDestructiveDisabled: return (.alias(.information300), .alias(.information700))
        case .textListTextDescriptionDestructiveHover: return (.alias(.information700), .alias(.information300))
        case .textListTrailingSubtextDefault: return (.alias(.information500), .alias(.information300))
        case .textListTrailingTextGeneral: return (.alias(.information500), .alias(.information300))
        case .textLoadersUploadControllerDefault: return (.alias(.informationWhite), .alias(.secondary800))
        case .textMainButtonDefaultDescriptionPrimaryDisabled: return (.alias(.primary250), .alias(.information500))
        case .textMainButtonDefaultDescriptionPrimaryEnabled: return (.alias(.primary500), .alias(.primary250))
        case .textMainButtonDefaultDescriptionPrimaryHover: return (.alias(.primary400), .alias(.primary200))
        case .textMainButtonDefaultDescriptionSecondaryDisabled: return (.alias(.information300), .alias(.information500))
        case .textMainButtonDefaultDescriptionSecondaryEnabled: return (.alias(.information800), .alias(.informationWhite))
        case .textMainButtonDefaultDescriptionSecondaryHover: return (.alias(.secondary700), .alias(.informationWhite))
        case .textMainButtonDefaultFilledPrimaryDisabled: return (.alias(.informationWhite), .alias(.information500))
        case .textMainButtonDefaultFilledPrimaryEnabled: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textMainButtonDefaultFilledPrimaryHover: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textMainButtonDefaultFilledSecondaryDisabled: return (.alias(.information500), .alias(.information500))
        case .textMainButtonDefaultFilledSecondaryEnabled: return (.alias(.information800), .alias(.informationWhite))
        case .textMainButtonDefaultFilledSecondaryHover: return (.alias(.information800), .alias(.informationWhite))
        case .textMainButtonDefaultGhostPrimaryDisabled: return (.alias(.primary250), .alias(.information500))
        case .textMainButtonDefaultGhostPrimaryEnabled: return (.alias(.primary500), .alias(.primary400))
        case .textMainButtonDefaultGhostPrimaryHover: return (.alias(.primary500), .alias(.primary200))
        case .textMainButtonDefaultGhostSecondaryDisabled: return (.alias(.information500), .alias(.information500))
        case .textMainButtonDefaultGhostSecondaryEnabled: return (.alias(.information800), .alias(.informationWhite))
        case .textMainButtonDefaultGhostSecondaryHover: return (.alias(.secondary800), .alias(.informationWhite))
        case .textMainButtonDefaultInversePrimaryDisabled: return (.alias(.information700), .alias(.information500))
        case .textMainButtonDefaultInversePrimaryEnabled: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textMainButtonDefaultInversePrimaryHover: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textMainButtonDefaultInverseSecondaryDisabled: return (.alias(.information700), .alias(.information500))
        case .textMainButtonDefaultInverseSecondaryEnabled: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textMainButtonDefaultInverseSecondaryHover: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textMainButtonDefaultLinkPrimaryDisabled: return (.alias(.primary250), .alias(.information500))
        case .textMainButtonDefaultLinkPrimaryEnabled: return (.alias(.primary500), .alias(.primary250))
        case .textMainButtonDefaultLinkPrimaryHover: return (.alias(.primary400), .alias(.primary200))
        case .textMainButtonDefaultLinkSecondaryDisabled: return (.alias(.information300), .alias(.information500))
        case .textMainButtonDefaultLinkSecondaryEnabled: return (.alias(.information800), .alias(.informationWhite))
        case .textMainButtonDefaultLinkSecondaryHover: return (.alias(.secondary700), .alias(.informationWhite))
        case .textMainButtonDefaultOutlinedPrimaryDisabled: return (.alias(.primary250), .alias(.information500))
        case .textMainButtonDefaultOutlinedPrimaryEnabled: return (.alias(.primary500), .alias(.primary250))
        case .textMainButtonDefaultOutlinedPrimaryHover: return (.alias(.primary400), .alias(.primary200))
        case .textMainButtonDefaultOutlinedSecondaryDisabled: return (.alias(.information300), .alias(.information500))
        case .textMainButtonDefaultOutlinedSecondaryEnabled: return (.alias(.information800), .alias(.informationWhite))
        case .textMainButtonDefaultOutlinedSecondaryHover: return (.alias(.information800), .alias(.informationWhite))
        case .textMainButtonDefaultTransparentPrimaryDisabled: return (.alias(.information300), .alias(.information500))
        case .textMainButtonDefaultTransparentPrimaryEnabled: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textMainButtonDefaultTransparentPrimaryHover: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textMainButtonDestructiveDescriptionPrimaryDisabled: return (.alias(.signalDestructive200), .alias(.information500))
        case .textMainButtonDestructiveDescriptionPrimaryEnabled: return (.alias(.signalDestructive500), .alias(.signalDestructive400))
        case .textMainButtonDestructiveDescriptionPrimaryHover: return (.alias(.signalDestructive300), .alias(.signalDestructive200))
        case .textMainButtonDestructiveDescriptionSecondaryDisabled: return (.alias(.information300), .alias(.information500))
        case .textMainButtonDestructiveDescriptionSecondaryEnabled: return (.alias(.information800), .alias(.informationWhite))
        case .textMainButtonDestructiveDescriptionSecondaryHover: return (.alias(.secondary700), .alias(.informationWhite))
        case .textMainButtonDestructiveFilledPrimaryDisabled: return (.alias(.informationWhite), .alias(.information500))
        case .textMainButtonDestructiveFilledPrimaryEnabled: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textMainButtonDestructiveFilledPrimaryHover: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textMainButtonDestructiveFilledSecondaryDisabled: return (.alias(.information500), .alias(.information500))
        case .textMainButtonDestructiveFilledSecondaryEnabled: return (.alias(.information800), .alias(.informationWhite))
        case .textMainButtonDestructiveFilledSecondaryHover: return (.alias(.information800), .alias(.informationWhite))
        case .textMainButtonDestructiveGhostPrimaryDisabled: return (.alias(.signalDestructive200), .alias(.information500))
        case .textMainButtonDestructiveGhostPrimaryEnabled: return (.alias(.signalDestructive500), .alias(.signalDestructive400))
        case .textMainButtonDestructiveGhostPrimaryHover: return (.alias(.signalDestructive500), .alias(.signalDestructive200))
        case .textMainButtonDestructiveGhostSecondaryDisabled: return (.alias(.information500), .alias(.information500))
        case .textMainButtonDestructiveGhostSecondaryEnabled: return (.alias(.information800), .alias(.informationWhite))
        case .textMainButtonDestructiveGhostSecondaryHover: return (.alias(.secondary800), .alias(.informationWhite))
        case .textMainButtonDestructiveInversePrimaryDisabled: return (.alias(.information700), .alias(.information500))
        case .textMainButtonDestructiveInversePrimaryEnabled: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textMainButtonDestructiveInversePrimaryHover: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textMainButtonDestructiveInverseSecondaryDisabled: return (.alias(.information700), .alias(.information500))
        case .textMainButtonDestructiveInverseSecondaryEnabled: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textMainButtonDestructiveInverseSecondaryHover: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textMainButtonDestructiveLinkPrimaryDisabled: return (.alias(.signalDestructive200), .alias(.information500))
        case .textMainButtonDestructiveLinkPrimaryEnabled: return (.alias(.signalDestructive500), .alias(.signalDestructive400))
        case .textMainButtonDestructiveLinkPrimaryHover: return (.alias(.signalDestructive300), .alias(.signalDestructive200))
        case .textMainButtonDestructiveLinkSecondaryDisabled: return (.alias(.information300), .alias(.information500))
        case .textMainButtonDestructiveLinkSecondaryEnabled: return (.alias(.information800), .alias(.informationWhite))
        case .textMainButtonDestructiveLinkSecondaryHover: return (.alias(.secondary700), .alias(.informationWhite))
        case .textMainButtonDestructiveOutlinedPrimaryDisabled: return (.alias(.signalDestructive300), .alias(.information500))
        case .textMainButtonDestructiveOutlinedPrimaryEnabled: return (.alias(.signalDestructive500), .alias(.signalDestructive300))
        case .textMainButtonDestructiveOutlinedPrimaryHover: return (.alias(.signalDestructive300), .alias(.signalDestructive200))
        case .textMainButtonDestructiveOutlinedSecondaryDisabled: return (.alias(.information300), .alias(.information500))
        case .textMainButtonDestructiveOutlinedSecondaryEnabled: return (.alias(.information800), .alias(.informationWhite))
        case .textMainButtonDestructiveOutlinedSecondaryHover: return (.alias(.information800), .alias(.informationWhite))
        case .textMenuListActive: return (.alias(.primary500), .alias(.informationWhite))
        case .textMenuListDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textMenuListHover: return (.alias(.information800), .alias(.informationWhite))
        case .textModalTextDescriptionDefault: return (.alias(.information700), .alias(.informationWhite))
        case .textModalTitleDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textReactionsChatReactionCountActive: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textReactionsChatReactionCountDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textReactionsPostCommentCountGeneral: return (.alias(.information500), .alias(.informationWhite))
        case .textReactionsPostReactionCountGeneral: return (.alias(.information500), .alias(.informationWhite))
        case .textReactionsReactionPopoverReactionNameGeneral: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textSheetsHeaderTextDescriptionDefault: return (.alias(.information500), .alias(.informationWhite))
        case .textSheetsHeaderTitleDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textSquareButtonDefaultPrimaryDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textSquareButtonDefaultPrimaryDisabled: return (.alias(.informationWhite), .alias(.information700))
        case .textSquareButtonDefaultPrimaryHover: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textSquareButtonDefaultSecondaryDefault: return (.alias(.information800), .alias(.informationWhite))
        case .textSquareButtonDefaultSecondaryDisabled: return (.alias(.information300), .alias(.information700))
        case .textSquareButtonDefaultSecondaryHover: return (.alias(.information800), .alias(.informationWhite))
        case .textSquareButtonDestructiveDefault: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textSquareButtonDestructiveDisabled: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textSquareButtonDestructiveHover: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textTabPillActive: return (.alias(.informationWhite), .alias(.informationWhite))
        case .textTabPillDefault: return (.alias(.information700), .alias(.information200))
        case .textTabPillDisabled: return (.alias(.information300), .alias(.information700))
        case .textTabPillHover: return (.alias(.information500), .alias(.information300))
        case .textTabPillPress: return (.alias(.information700), .alias(.information700))
        case .textTabUnderlinedActive: return (.alias(.primary500), .alias(.primary400))
        case .textTabUnderlinedDefault: return (.alias(.information700), .alias(.information300))
        case .textTabUnderlinedDisabled: return (.alias(.information300), .alias(.information700))
        case .textTabUnderlinedHover: return (.alias(.information500), .alias(.information500))
        case .textTabUnderlinedPress: return (.alias(.information500), .alias(.information500))
        case .textTimestampDefault: return (.alias(.information500), .alias(.information500))
        case .textTopNavigationDescription: return (.alias(.information500), .alias(.informationWhite))
        case .textTopNavigationFeedback: return (.alias(.information700), .alias(.informationWhite))
        case .textTopNavigationTitle: return (.alias(.information800), .alias(.informationWhite))
        }
    }
}
