//
//  AmityBadge.swift
//  AmityUIKit4
//
//  Design-system ATOM — the atomic count/status chip (base primitive + semantic presets).
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/Badge/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  Conventions (see AmityToggle, the C1 pattern-setter):
//   • Presentational — no interaction, no internal state; renders straight from its inputs.
//     The Badge Token grammar's `State` axis is `Default`-only, so there is no hover/press to manage.
//   • Colours resolve through `viewConfig.color(_:)` (page/component-scoped theme).
//   • Icons come from `AmityIcon.DesignSystem` (template-rendered, tinted by an Icon/Badge/* token).
//   • Additive — this does not touch any existing component.
//
//  Two layers, exactly as the spec:
//   1. Base badge  — the shape/size primitive, bound to `{Surface,Text,Icon,Border}/Badge/AtomicBadge/*`.
//   2. Semantic presets — `preset:` selects a `.../Badge/SemanticBadge/{Family}/{Case}` surface plus its
//      Text or Icon companion. Only presets whose tokens actually exist in colors-v2 are modeled here;
//      families/cases with no authored token are omitted and documented at the bottom of this file.
//

import SwiftUI

/// Which content the badge renders (Figma `Display` axis).
enum BadgeVariantEnum {
    /// Text label — Figma Display=Default. Uses `label`; `icon` is ignored.
    case label
    /// Icon glyph only — Figma Display=Icon Only. Uses `icon`; `label` is ignored.
    case icon
}

/// Corner treatment (Figma `Style` axis).
enum BadgeShapeEnum {
    /// Radius 256 — exceeds half-height at every size, so it renders as a pill/circle. Clamped to H/2.
    case round
    /// Radius 4.
    case square
}

/// Surface treatment (Figma `Type` axis).
enum BadgeFillEnum {
    /// Coloured surface — base primitive binds `Surface/Badge/AtomicBadge/Filled/Default`.
    case filled
    /// Transparent surface — the base primitive has **no** `AtomicBadge/Ghost` surface token authored,
    /// so ghost renders a clear fill (label/glyph keep the non-inverse tokens). Per the spec, ghost is
    /// only *confirmed* for `label` + `square`, sizes 20–32; other combinations are an unconfirmed gap.
    case ghost
}

/// One of the six intrinsic badge heights {14, 16, 20, 24, 28, 32}. Height == this value at every size
/// (vertical padding is 0); width grows with the label. `size24` is the documented default.
enum BadgeSizeEnum {
    case size14, size16, size20, size24, size28, size32

    var pt: CGFloat {
        switch self {
        case .size14: return 14
        case .size16: return 16
        case .size20: return 20
        case .size24: return 24
        case .size28: return 28
        case .size32: return 32
        }
    }
}

/// Semantic family + case preset. Resolves the Surface / Text / Icon tokens for a meaning automatically;
/// when omitted the badge falls back to the base `AtomicBadge` primitive.
///
/// Only cases with an authored `.../Badge/SemanticBadge/{Family}/{Case}` token are listed — see the
/// gap notes at the bottom of this file for the families/cases the token set does not (yet) cover.
enum AmityBadgePreset: Equatable {
    case general(General)
    case postStatus(PostStatus)
    case userStatus(UserStatus)
    case chat(Chat)
    case live(Live)
    case event(Event)
    case community(Community)

    /// General family. Label tone is shared across all cases (`Text/Badge/SemanticBadge/General/Default/Default`).
    enum General: Equatable { case notification, dot, selection, duration }
    /// Post-status family. Only these three have surface tokens (Sponsored also has a glyph token).
    enum PostStatus: Equatable { case featured, sponsored, totalMedia }
    /// User-status family. Only `moderator` has a surface token; the rest are glyph-only (no surface authored).
    enum UserStatus: Equatable { case moderator, muted, banned, `private`, brand }
    /// Chat family.
    enum Chat: Equatable { case mention, archived, `private` }
    /// Live family. Authored cases are Alert/Indicator/Information (surface) + General (label+glyph, no surface).
    /// The spec's `host`/`coHost`/`watchingNow` Live cases have no token and are omitted.
    enum Live: Equatable { case alert, indicator, information, general }
    /// Event family. `default`/`host` have surface tokens; `general` is label-only (no surface).
    enum Event: Equatable { case `default`, host, general }
    /// Community family. `general`/`official` have surface+glyph; `private` is glyph-only (no surface).
    enum Community: Equatable { case general, official, `private` }
}

/// Atomic count/status chip — a text label or an icon glyph inside a filled or ghost surface, round or
/// square, across six sizes. Presentational only.
///
///     // base primitive
///     AmityBadge(variant: .label, label: "NEW", viewConfig: viewConfig)
///     // semantic preset (unread count)
///     AmityBadge(variant: .label, label: "9", preset: .general(.notification), viewConfig: viewConfig)
///     // semantic preset (moderator shield)
///     AmityBadge(variant: .icon, icon: .shieldCheckF, preset: .userStatus(.moderator), viewConfig: viewConfig)
struct AmityBadge: View {

    private let variant: BadgeVariantEnum
    private let label: String?
    private let icon: AmityIcon.DesignSystem?
    private let shape: BadgeShapeEnum
    private let fill: BadgeFillEnum
    private let size: BadgeSizeEnum
    private let border: Bool
    private let preset: AmityBadgePreset?
    private let viewConfig: AmityViewConfigController

    init(variant: BadgeVariantEnum,
         label: String? = nil,
         icon: AmityIcon.DesignSystem? = nil,
         shape: BadgeShapeEnum = .round,
         fill: BadgeFillEnum = .filled,
         size: BadgeSizeEnum = .size24,
         border: Bool = false,
         preset: AmityBadgePreset? = nil,
         viewConfig: AmityViewConfigController) {
        self.variant = variant
        self.label = label
        self.icon = icon
        self.shape = shape
        self.fill = fill
        self.size = size
        self.border = border
        self.preset = preset
        self.viewConfig = viewConfig
    }

    var body: some View {
        content
            .padding(.horizontal, variant == .label ? horizontalPadding : 0)
            .frame(width: variant == .icon ? size.pt : nil, height: size.pt)
            .background(badgeShape.fill(surfaceColor))
            .overlay(borderOverlay)
            .clipShape(badgeShape)
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch variant {
        case .label:
            if let label, !label.isEmpty {
                Text(label)
                    .applyTextStyle(labelStyle(Color(viewConfig.color(resolvedTextToken))))
                    .lineLimit(1)
                    .fixedSize()
            } else {
                // Surface-only badge (e.g. General/Dot) — nothing to draw inside.
                EmptyView()
            }
        case .icon:
            if let icon {
                Image(icon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: glyphSize, height: glyphSize)
                    .foregroundColor(Color(viewConfig.color(resolvedIconToken)))
            } else {
                // Icon variant with no glyph = a solid dot/indicator; the surface carries the meaning.
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if border {
            badgeShape.strokeBorder(Color(viewConfig.color(resolvedBorderToken)), lineWidth: 1)
        }
    }

    // MARK: - Geometry

    /// Radius 256 (round) clamps to H/2 → a pill for wide labels, a circle for the square icon frame.
    private var cornerRadius: CGFloat {
        switch shape {
        case .round:  return size.pt / 2
        case .square: return 4
        }
    }

    private var badgeShape: RoundedRectangle { RoundedRectangle(cornerRadius: cornerRadius) }

    /// Per-side horizontal inset for the label variant (spec Geometry table). Vertical padding is 0.
    /// Round-ghost and 14/16-ghost aren't tabulated in the extraction, so they fall back to the Filled
    /// value at the same size (documented gap).
    private var horizontalPadding: CGFloat {
        switch (shape, fill, size) {
        case (.round, _, .size14), (.round, _, .size16): return 4
        case (.round, _, .size20):                       return 6
        case (.round, _, .size24), (.round, _, .size28): return 8
        case (.round, _, .size32):                       return 12
        case (.square, .filled, .size14), (.square, .filled, .size16): return 2
        case (.square, .filled, .size20):                              return 6
        case (.square, .filled, .size24), (.square, .filled, .size28): return 8
        case (.square, .filled, .size32):                              return 12
        case (.square, .ghost, .size20), (.square, .ghost, .size24), (.square, .ghost, .size28): return 2
        case (.square, .ghost, .size32):                                                         return 4
        // ghost 14/16 has no confirmed instance → mirror Filled.
        case (.square, .ghost, .size14), (.square, .ghost, .size16): return 2
        }
    }

    /// Glyph inset inside the icon-only footprint. The spec lists layout padding 0 for icon-only, but the
    /// status-icon ring composite uses ~2 pt; ~60% of the frame keeps the template glyph off the edge.
    /// Some presets specify a tighter ring in Figma and override the default ratio (e.g. Chat/Private
    /// renders a 12 pt lock inside a 16 pt badge — a 0.75 ratio, not 0.6).
    private var glyphSize: CGFloat { (size.pt * glyphRatio).rounded() }

    /// Glyph-to-frame ratio. Defaults to 0.6; presets whose Figma glyph differs from the atomic ring
    /// override it here so the icon matches the design node.
    private var glyphRatio: CGFloat {
        switch preset {
        case .chat(.private):         return 0.85
        case .userStatus(.moderator): return 0.85 
        default:                      return 0.6
        }
    }

    /// Text style scales with the badge height so the label fits within the frame.
    private func labelStyle(_ color: Color) -> AmityTextStyle {
        switch size {
        case .size14, .size16: return .captionSmall(color)
        case .size20, .size24: return .caption(color)
        case .size28, .size32: return .bodyBold(color)
        }
    }

    // MARK: - Token resolution

    /// A coloured (non-clear) surface exists when the base primitive is filled, or the preset supplies one.
    private var hasFilledSurface: Bool { resolvedSurfaceToken != nil }

    private var surfaceColor: Color {
        guard let token = resolvedSurfaceToken else { return .clear }
        return Color(viewConfig.color(token))
    }

    private var resolvedSurfaceToken: AmityColorToken? {
        if let preset { return preset.surfaceToken }
        return fill == .filled ? .surfaceBadgeAtomicBadgeFilledDefault : nil
    }

    /// Label tone. Preset token wins; otherwise the base primitive uses the Inverse (white) token on a
    /// coloured/filled surface and the Default token on a transparent one (the resolved aliases confirm
    /// Default is dark, Inverse is white — filled=primary500 needs the white one for contrast).
    private var resolvedTextToken: AmityColorToken {
        if let preset, let token = preset.textToken { return token }
        return hasFilledSurface ? .textBadgeAtomicBadgeInverse : .textBadgeAtomicBadgeDefault
    }

    /// Glyph tint — same Default/Inverse fallback logic as the label.
    private var resolvedIconToken: AmityColorToken {
        if let preset, let token = preset.iconToken { return token }
        return hasFilledSurface ? .iconBadgeAtomicBadgeInverse : .iconBadgeAtomicBadgeDefault
    }

    /// Border ring token. Family-scoped tokens exist for General and Live; everything else uses the
    /// atomic ring.
    private var resolvedBorderToken: AmityColorToken {
        preset?.borderToken ?? .borderBadgeAtomicBadgeDefault
    }

    private var accessibilityLabel: String {
        switch variant {
        case .label: return label ?? ""
        case .icon:  return label ?? ""
        }
    }
}

// MARK: - Preset → token mapping

/// Maps each modeled preset case to its authored colors-v2 tokens. `nil` means the family/case has no
/// token for that role (the badge falls back to the base tokens for Text/Icon, or a clear surface).
private extension AmityBadgePreset {

    var surfaceToken: AmityColorToken? {
        switch self {
        case .general(.notification):  return .surfaceBadgeSemanticBadgeGeneralNotification
        case .general(.dot):           return .surfaceBadgeSemanticBadgeGeneralDot
        case .general(.selection):     return .surfaceBadgeSemanticBadgeGeneralSelection
        case .general(.duration):      return .surfaceBadgeSemanticBadgeGeneralDuration
        case .postStatus(.featured):   return .surfaceBadgeSemanticBadgePostStatusFeatured
        case .postStatus(.sponsored):  return .surfaceBadgeSemanticBadgePostStatusSponsored
        case .postStatus(.totalMedia): return .surfaceBadgeSemanticBadgePostStatusTotalMedia
        case .userStatus(.moderator):  return .surfaceBadgeSemanticBadgeUserStatusModerator
        case .userStatus:              return nil // muted/banned/private/brand: glyph-only, no surface token
        case .chat(.mention):          return .surfaceBadgeSemanticBadgeChatMention
        case .chat(.archived):         return .surfaceBadgeSemanticBadgeChatArchived
        case .chat(.private):          return .surfaceBadgeSemanticBadgeChatPrivate
        case .live(.alert):            return .surfaceBadgeSemanticBadgeLiveAlert
        case .live(.indicator):        return .surfaceBadgeSemanticBadgeLiveIndicator
        case .live(.information):      return .surfaceBadgeSemanticBadgeLiveInformation
        case .live(.general):          return nil // Live/General has no surface token
        case .event(.default):         return .surfaceBadgeSemanticBadgeEventDefault
        case .event(.host):            return .surfaceBadgeSemanticBadgeEventHost
        case .event(.general):         return nil // Event/General has no surface token
        case .community(.general):     return .surfaceBadgeSemanticBadgeCommunityGeneral
        case .community(.official):    return .surfaceBadgeSemanticBadgeCommunityOfficial
        case .community(.private):     return nil // Community/Private is glyph-only, no surface token
        }
    }

    var textToken: AmityColorToken? {
        switch self {
        case .general:                 return .textBadgeSemanticBadgeGeneralDefaultDefault // shared General label
        case .postStatus(.featured):   return .textBadgeSemanticBadgePostStatusFeaturedDefault
        case .postStatus(.sponsored):  return .textBadgeSemanticBadgePostStatusSponsoredDefault
        case .postStatus(.totalMedia): return .textBadgeSemanticBadgePostStatusTotalMediaGeneral
        case .userStatus(.moderator):  return .textBadgeSemanticBadgeUserStatusModeratorDefault
        case .userStatus:              return nil
        case .chat(.archived):         return .textBadgeSemanticBadgeChatArchivedDefault
        case .chat(.mention):          return nil // Mention is glyph-only
        case .chat(.private):          return nil // Private is a lock glyph badge, no label
        case .live(.general):          return .textBadgeSemanticBadgeLiveGeneralDefault
        case .live:                    return nil
        case .event(.host):            return .textBadgeSemanticBadgeEventHostDefault
        case .event(.general):         return .textBadgeSemanticBadgeEventGeneralDefault
        case .event(.default):         return nil
        case .community:               return nil // Community presets are glyph-only
        }
    }

    var iconToken: AmityColorToken? {
        switch self {
        case .postStatus(.sponsored):  return .iconBadgeSemanticBadgePostStatusSponsoredDefault
        case .postStatus:              return nil
        case .userStatus(.moderator):  return .iconBadgeSemanticBadgeUserStatusModeratorDefault
        case .userStatus(.muted):      return .iconBadgeSemanticBadgeUserStatusMutedDefault
        case .userStatus(.banned):     return .iconBadgeSemanticBadgeUserStatusBannedDefault
        case .userStatus(.private):    return .iconBadgeSemanticBadgeUserStatusPrivateDefault
        case .userStatus(.brand):      return .iconBadgeSemanticBadgeUserStatusBrandDefault
        case .chat(.mention):          return .iconBadgeSemanticBadgeChatMentionDefault
        case .chat(.archived):         return .iconBadgeSemanticBadgeChatArchivedDefault
        case .chat(.private):          return .iconBadgeSemanticBadgeChatPrivateDefault
        case .live(.alert):            return .iconBadgeSemanticBadgeLiveAlertDefault
        case .live(.general):          return .iconBadgeSemanticBadgeLiveGeneralDefault
        case .live:                    return nil
        case .event(.host):            return .iconBadgeSemanticBadgeEventHostDefault
        case .event:                   return nil
        case .community(.general):     return .iconBadgeSemanticBadgeCommunityGeneralDefault
        case .community(.official):    return .iconBadgeSemanticBadgeCommunityOfficialDefault
        case .community(.private):     return .iconBadgeSemanticBadgeCommunityPrivateDefault
        case .general:                 return nil
        }
    }

    /// Family-scoped ring token, used when `border == true`. Only General and Live have a semantic ring;
    /// all others use the atomic ring (`Border/Badge/AtomicBadge/Default`) via the view's fallback.
    var borderToken: AmityColorToken {
        switch self {
        case .general: return .borderBadgeSemanticBadgeGeneralDefault
        case .live:    return .borderBadgeLiveStatusLiveDefault
        default:       return .borderBadgeAtomicBadgeDefault
        }
    }
}
