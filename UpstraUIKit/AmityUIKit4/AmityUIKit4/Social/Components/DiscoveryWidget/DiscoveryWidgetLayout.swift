//
//  DiscoveryWidgetLayout.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/9/26.
//

import SwiftUI

/// The two Discovery Widget layouts, selected by **container** width at the `769` boundary
/// (`AmityDiscoveryWidgetComponent` v1 REQ-040). Not by device class, screen width or user agent.
public enum DiscoveryWidgetLayout {
    /// container width < 769 — 16 inset, 343 cards, 8 gap
    case compact
    /// container width >= 769 — 0 inset, 375 cards, 16 gap
    case expanded

    static let breakpoint: CGFloat = 769

    init(containerWidth: CGFloat) {
        self = containerWidth >= DiscoveryWidgetLayout.breakpoint ? .expanded : .compact
    }
}

/// Every geometry value the widget and its cards use, read from the Discovery Widget node tree
/// (Figma `2BIjktS6x3hm2gznAs2Dg8`, page `[Chunk 3] UI Widget`). The legacy theme expresses colour
/// but not spacing, so the design-system primitives live here as constants.
enum DiscoveryWidgetMetrics {

    // MARK: - Widget shell

    /// Symmetric top/bottom inset on the widget container. Horizontal inset is always 0 — the host
    /// page owns the gutter.
    static func containerVerticalPadding(_ layout: DiscoveryWidgetLayout) -> CGFloat {
        layout == .expanded ? 24 : 16
    }

    /// Heading row height: 32 expanded, 24 compact. The expanded row is sized for the web widget's
    /// 32-tall nav buttons; mobile draws no buttons but keeps the height, so the widget measures the
    /// same 584 at that breakpoint on both platforms.
    static func headingHeight(_ layout: DiscoveryWidgetLayout) -> CGFloat {
        layout == .expanded ? 32 : 24
    }

    /// Gap from the bottom of the heading row to the top of the card track.
    static func headingToTrackGap(_ layout: DiscoveryWidgetLayout) -> CGFloat {
        layout == .expanded ? 24 : 16
    }

    /// Track inset. Compact pads 16 on *both* sides (`pad=0/16/0/16`); the content box is then
    /// exactly one card wide and the following cards overflow, leaving the 8 peek.
    static func trackInset(_ layout: DiscoveryWidgetLayout) -> CGFloat {
        layout == .expanded ? 0 : 16
    }

    static func cardWidth(_ layout: DiscoveryWidgetLayout) -> CGFloat {
        layout == .expanded ? 375 : 343
    }

    static func cardGap(_ layout: DiscoveryWidgetLayout) -> CGFloat {
        layout == .expanded ? 16 : 8
    }

    /// Compact heading is inset 16 from both container edges; expanded heading is flush.
    static func headingHorizontalInset(_ layout: DiscoveryWidgetLayout) -> CGFloat {
        layout == .expanded ? 0 : 16
    }

    /// While loading, the heading's title text is hidden and a pill stands in for it — `72 × 16`,
    /// vertically centred in the heading row (Figma `1176:92972`, `Skeleton Wrapper`). Without it the
    /// heading renders blank, because `topicName` is API-sourced and unknown until the pool resolves.
    static let headingSkeletonWidth: CGFloat = 72
    static let headingSkeletonHeight: CGFloat = 16

    // MARK: - Card slot budget
    //
    // Every `Widget post` instance on the page measures exactly 480 tall. The budget is fixed, not
    // proportional, which is what makes truncation deterministic across platforms:
    //
    //   52 + 392 + 36               = 480   (no media / poll)
    //   52 +  96 + 296 + 36         = 480   (media or poll present)

    static let cardHeight: CGFloat = 480
    static let cardCornerRadius: CGFloat = 8

    static let headerHeight: CGFloat = 52
    static let engagementHeight: CGFloat = 36
    static let mediaBlockHeight: CGFloat = 296
    static let pollBlockHeight: CGFloat = 296

    /// What the header and engagement bar leave for everything between them: `480 − 52 − 36`.
    static let contentBudget: CGFloat = cardHeight - headerHeight - engagementHeight

    /// A card with no media or poll gives the whole remainder to its text.
    static let textBlockHeightWithoutMedia: CGFloat = contentBudget

    /// A poll card's text. Not a budget the text is padded out to — it is what a title plus two body
    /// lines measures, and it falls out of the poll block being the one slot that does not flex.
    static let textBlockHeightWithPoll: CGFloat = contentBudget - pollBlockHeight

    /// The loading skeleton hides the engagement bar, so its text slot absorbs that `36`:
    /// `52 + 428 = 480`. Unrelated to the slots above — a skeleton card has no media block to
    /// share the remainder with.
    static let skeletonTextBlockHeight: CGFloat = 428

    /// The media slot never shrinks past this, so a long caption truncates rather than squeezing the
    /// thumbnail away.
    static let mediaSlotFloor: CGFloat = 296

    /// Hence the most a caption may take on a media card before it truncates.
    static let maximumTextHeightWithMedia: CGFloat = contentBudget - mediaSlotFloor

    /// How tall the text slot is allowed to be. On a media card this is a **maximum** — the block
    /// hugs its caption and the media absorbs what is left, so a short caption buys a bigger
    /// thumbnail rather than leaving whitespace. Everywhere else it is the exact height, because
    /// nothing else is competing for the remainder.
    static func textBlockHeight(for variant: DiscoveryWidgetCardVariant) -> CGFloat {
        switch variant {
        case .image, .video:
            return maximumTextHeightWithMedia
        case .poll:
            return textBlockHeightWithPoll
        case .text, .link:
            return textBlockHeightWithoutMedia
        }
    }

    // MARK: - Card internals

    static let cardHorizontalInset: CGFloat = 16
    /// Header pads `12/16/0/16` — the 52 height is `12 + 40`, with no bottom padding.
    static let headerTopPadding: CGFloat = 12
    static let avatarSize: CGFloat = 32
    static let avatarToContentGap: CGFloat = 8
    static let headerRowGap: CGFloat = 2
    static let headerNameGap: CGFloat = 4
    /// The design's `To Arrow` is a **padded icon frame**, not a glyph size: a `16` box carrying a
    /// chevron that inks about `5 × 8` (measured off the `1072:129187` render). `arrowIcon` is a
    /// tight `6 × 9` asset with no padding of its own, so framing it at the box size draws the
    /// chevron at `16` — twice what the design shows. The box is what keeps the 4pt gaps either side
    /// of it honest; the glyph inside it is what the eye actually reads.
    static let toArrowSize: CGFloat = 16
    static let toArrowGlyphSize: CGFloat = 8

    /// Text block pads `8/16/8/16` with a 16 gap between title and body.
    static let textBlockVerticalPadding: CGFloat = 8
    static let textTitleToBodyGap: CGFloat = 16
    static let titleLineHeight: CGFloat = 24   // Title Bold — SF Pro 17/24
    static let bodyLineHeight: CGFloat = 20    // Body Regular — SF Pro 15/20

    /// What those styles actually *render* at: `20.3` and `17.9`. The 24/20 above are the design's
    /// declared line heights, and no `lineSpacing` is applied anywhere, so a line count derived from
    /// them under-counts by roughly one line in six — the body then stops well above the bottom of
    /// the slot it was supposed to fill. Line *counts* use these; slot arithmetic uses the design's.
    static var renderedTitleLineHeight: CGFloat {
        AmityTextStyle.titleBold(.clear).getUIFont().lineHeight
    }

    static var renderedBodyLineHeight: CGFloat {
        AmityTextStyle.body(.clear).getUIFont().lineHeight
    }
    /// The 392 slot shows the title wrapping to at most 4 lines before the body takes the remainder.
    static let titleMaxLinesInTallSlot: Int = 4

    /// Alongside media or a poll, title and body each hug their own content up to their own cap —
    /// one line and two lines. These caps are what bound the text block: at their maximum it
    /// measures `8 + 24 + 16 + 40 + 8 = 96`, which is exactly where the media reaches its `296`
    /// floor. The floor falls out of the caps rather than being enforced on top of them.
    static let titleLineLimitBesideMedia: Int = 1
    static let bodyLineLimitBesideMedia: Int = 2


    /// The link preview lives **inside** the text slot's budget (Figma `1072:129187`: the
    /// link-preview slot is a child of `Post / Text`), so its height is subtracted from the lines
    /// available to the body rather than added below the slot.
    ///
    /// It is the same hero card the feed draws, not a compact variant: `171.5` media over an `84`
    /// information block. That fits the `392` slot with `108.5` left for the title and body, which is
    /// what the design measures — `8 + 24 + 16 + 68.5 + 12 + 255.5 + 8`.
    static let linkPreviewHeight: CGFloat = 255.5
    static let linkPreviewMediaHeight: CGFloat = 171.5
    /// Information block pads `12` all round, with the domain sitting `2` under the title.
    static let linkPreviewInfoPadding: CGFloat = 12
    static let linkPreviewTitleToUrlGap: CGFloat = 2
    /// Gap from the body to the preview. Narrower than `textTitleToBodyGap` — the preview is a block
    /// under the text, not another paragraph of it.
    static let linkPreviewTopGap: CGFloat = 12

    /// Media keeps `8` top and bottom padding whatever the slot works out to, so its content is
    /// always `slot − 16`. The `280` floor pairs with the `296` slot floor.
    static let mediaVerticalPadding: CGFloat = 8
    static let mediaContentFloor: CGFloat = mediaSlotFloor - (mediaVerticalPadding * 2)

    /// `Video Controls` measures `40 × 40` at `(168, 128)` in a `375 × 296` block — dead centre:
    /// `(375 − 40) / 2 = 167.5` and `(296 − 40) / 2 = 128` (Figma `I1072:130313;19998:38777`).
    static let playIndicatorSize: CGFloat = 40

    /// Trailing affordance on a multi-attachment thumbnail: a `32` circle on the same 50 %-black
    /// scrim as the counter pill, centred on the media content box and inset `8` from the card's
    /// trailing edge. Measured off the `1072:130013` render — glyph centre `(350.5, 295.5)` in a
    /// `375 × 480` card, circle edges at `y 279.5` and `y 311.5`, which puts its centre on the media
    /// block's own centre of `296`.
    ///
    /// Like the play glyph it is an **indicator, not a control**: the card still renders frame 1
    /// only and is still a single tap target. The spec's asset registry does not list it — the
    /// design does draw it (PDT-5499).
    static let mediaNextIndicatorSize: CGFloat = 32
    /// The chevron inks `8 × 14` in the design. `arrowIcon` is a tight `6 × 9`, so a `14` box fits it
    /// at `9.3 × 14` — same glyph-inside-box treatment as `toArrowGlyphSize`.
    static let mediaNextIndicatorGlyphSize: CGFloat = 14
    static let mediaOverlayInset: CGFloat = 8

    /// Engagement stat row is 20 tall, vertically centred in the 36 bar (`pad=8/0/8/0`), with a
    /// **fixed** 12 itemSpacing — `229 + 12 + 102 = 343` fills the content box exactly.
    static let engagementRowHeight: CGFloat = 20
    static let engagementVerticalPadding: CGFloat = 8
    static let engagementGap: CGFloat = 12

    // MARK: - Poll block

    static let pollTopPadding: CGFloat = 8
    static let pollOptionsToFooterGap: CGFloat = 16
    /// Footer is `See full results` 40 + gap 12 + status row 18.
    static let pollFooterHeight: CGFloat = 70
    static let pollSeeFullResultsHeight: CGFloat = 40
    static let pollFooterRowGap: CGFloat = 12
    static let pollStatusRowHeight: CGFloat = 18
    static let pollStatusSeparatorInset: CGFloat = 4

    static let pollTextOptionHeight: CGFloat = 80
    static let pollOptionGap: CGFloat = 8
    static let pollOptionPadding: CGFloat = 12
    static let pollProgressBarHeight: CGFloat = 8
    /// The bar is ten discrete 10% segments, not a proportional fill: a 34% share lights three.
    static let pollProgressSegmentCount: Int = 10

    static let pollImageOptionHeight: CGFloat = 181.6
    static let pollImageThumbnailHeight: CGFloat = 107.6
    static let pollImageThumbnailCornerRadius: CGFloat = 4
    static let pollImageThumbnailToLabelGap: CGFloat = 12
    static let pollImageCaptionHeight: CGFloat = 20
    static let pollImageVoterRowHeight: CGFloat = 18

    /// Vertical space the options list gets inside the fixed 296 poll slot, once the top padding,
    /// the options→footer gap and the footer are taken out.
    static var pollOptionsBudget: CGFloat {
        pollBlockHeight - pollTopPadding - pollOptionsToFooterGap - pollFooterHeight
    }

    /// How many stacked 80-tall options fit `pollOptionsBudget` at an 88 pitch. Evaluates to 2 —
    /// three would need 256 against a 202 budget. Computed rather than hardcoded so the cap follows
    /// the budget if a slot height ever changes (Plan 39 Q17 reads it either way).
    static var pollVisibleTextOptionCount: Int {
        let pitch = pollTextOptionHeight + pollOptionGap
        return max(1, Int((pollOptionsBudget + pollOptionGap) / pitch))
    }

    /// Rows of two image options that fit the same budget. Evaluates to 1 row, i.e. 2 options.
    static var pollVisibleImageOptionCount: Int {
        let pitch = pollImageOptionHeight + pollOptionGap
        let rows = max(1, Int((pollOptionsBudget + pollOptionGap) / pitch))
        return rows * 2
    }

    /// Image options are two per row: `(contentWidth − gap) / 2`. Computed, never hardcoded as 167.5.
    static func pollImageOptionWidth(cardWidth: CGFloat) -> CGFloat {
        let contentWidth = cardWidth - (cardHorizontalInset * 2)
        return (contentWidth - pollOptionGap) / 2
    }
}
