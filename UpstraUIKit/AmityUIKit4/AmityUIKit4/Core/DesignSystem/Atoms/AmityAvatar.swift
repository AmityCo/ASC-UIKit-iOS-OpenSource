//
//  AmityAvatar.swift
//  AmityUIKit4
//
//  Design-system ATOM — user/community avatar (Image / Icon / Text).
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/Avatar/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  Follows the conventions set by AmityToggle (the C1 pattern-setter):
//   • Presentational — the consumer supplies content (imageUrl/initials/state); the
//     atom draws it and never fetches or mutates state.
//   • Colours resolve through `viewConfig.color(_:)` (page/component-scoped theme).
//   • The icon-variant glyph comes from `AmityIcon.DesignSystem` (template-rendered,
//     tinted by an Icon/* token).
//   • Additive — this is a NEW atom. It does NOT touch the Social-shared
//     `AmityUserProfileImageView`; that component is left untouched.
//
//  Decoupling note (Avatar ↔ Badge): the spec's `indicator` slot is authored as an
//  `AmityBadge` instance, which would couple this atom to the (separately built) Badge
//  atom. To keep Avatar buildable in isolation, the indicator is exposed here as an
//  optional generic `AnyView?` rendered bottom-right. A consumer passes whatever badge
//  view it wants; when Badge lands, `AnyView(AmityBadge(...))` drops straight in.
//

import SwiftUI

/// Which content the avatar renders.
enum AvatarVariantEnum {
    case image   // photo covers the surface
    case icon    // default-person glyph fallback
    case text    // initials fallback
}

/// Frame style — full circle or squared corners.
enum AvatarStyleEnum {
    case rounded  // full circle; radius = size/2
    case squared  // flat corners; radius scales with size (4/8/16/24)
}

/// The 8 intrinsic avatar sizes, in points (raw value = pt).
enum AvatarSizeEnum: CGFloat {
    case size16 = 16
    case size24 = 24
    case size28 = 28
    case size32 = 32
    case size40 = 40   // default
    case size56 = 56
    case size64 = 64
    case size120 = 120

    /// Side length in points.
    var points: CGFloat { rawValue }
}

/// Visual state. iOS has no hover, so `.hover` renders identically to `.default`
/// (the Avatar token family has only Default values). `.skeleton` swaps the surface
/// for the shimmer treatment.
enum AvatarStateEnum {
    case `default`
    case hover
    case skeleton
}

/// Atomic user/community avatar.
///
///     AmityAvatar(variant: .image,
///                 imageUrl: user.avatarURL,
///                 size: .size40,
///                 borderWidth: 2,
///                 viewConfig: viewConfig)
struct AmityAvatar: View {

    private let variant: AvatarVariantEnum
    private let imageUrl: String?
    private let initials: String?
    private let style: AvatarStyleEnum
    private let size: AvatarSizeEnum
    private let state: AvatarStateEnum
    private let borderWidth: CGFloat
    private let label: String?
    private let indicator: AnyView?
    private let viewConfig: AmityViewConfigController

    init(variant: AvatarVariantEnum,
         imageUrl: String? = nil,
         initials: String? = nil,
         style: AvatarStyleEnum = .rounded,
         size: AvatarSizeEnum = .size40,
         state: AvatarStateEnum = .default,
         borderWidth: CGFloat = 0,
         label: String? = nil,
         indicator: AnyView? = nil,
         viewConfig: AmityViewConfigController) {
        self.variant = variant
        self.imageUrl = imageUrl
        self.initials = initials
        self.style = style
        self.size = size
        self.state = state
        self.borderWidth = borderWidth
        self.label = label
        self.indicator = indicator
        self.viewConfig = viewConfig
    }

    var body: some View {
        VStack(spacing: 4) {
            avatarBox
            if let label {
                Text(label)
                    .applyTextStyle(.caption(Color(viewConfig.color(.textAvatarLabelDefault))))
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Avatar box (surface + content + border + indicator)

    private var avatarBox: some View {
        content
            .frame(width: size.points, height: size.points)
            .clipShape(clipShape)
            .overlay(borderRing)
            .overlay(indicatorSlot, alignment: .bottomTrailing)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .skeleton:
            // Loading shimmer surface — overrides `variant`, per spec.
            // Simplified to a flat skeleton fill (no animated shimmer) to keep the atom
            // self-contained; the shimmer treatment can be layered on later.
            clipShape.fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
        case .default, .hover:
            switch variant {
            case .image:  imageContent
            case .icon:   iconContent
            case .text:   textContent
            }
        }
    }

    // MARK: Variant content

    /// Image variant: loads via the project's iOS-14-compatible `AsyncImage`
    /// (Kingfisher-backed) with the fallback profile surface as the loading/failure
    /// placeholder. Deliberately reuses this simple existing loader rather than any
    /// heavier avatar infra, and does not touch `AmityUserProfileImageView`.
    private var imageContent: some View {
        AsyncImage(placeholderView: { fallbackSurface },
                   url: URL(string: imageUrl ?? ""),
                   contentMode: .fill)
    }

    /// Icon variant: fallback surface + default-person glyph tinted by `Icon/Avatar/Default`.
    private var iconContent: some View {
        ZStack {
            fallbackSurface
            Image(AmityIcon.DesignSystem.userR.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: glyphSize, height: glyphSize)
                .foregroundColor(Color(viewConfig.color(.iconAvatarDefault)))
        }
    }

    /// Text variant: fallback surface + initials tinted by `Text/Avatar/Atomic/General`.
    private var textContent: some View {
        ZStack {
            fallbackSurface
            Text(initials ?? "")
                .applyTextStyle(.custom(initialsFontSize, .semibold,
                                        Color(viewConfig.color(.textAvatarAtomicGeneral))))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(2)
        }
    }

    /// Fallback fill shown behind icon/text glyphs (and while an image loads).
    private var fallbackSurface: some View {
        clipShape.fill(Color(viewConfig.color(.surfaceAvatarProfileDefault)))
    }

    // MARK: Border ring

    @ViewBuilder
    private var borderRing: some View {
        if borderWidth > 0 {
            clipShape.strokeBorder(Color(viewConfig.color(.borderAvatarProfileDefault)),
                                   lineWidth: borderWidth)
        }
    }

    // MARK: Indicator slot (decoupled from Badge — see file header)

    @ViewBuilder
    private var indicatorSlot: some View {
        if let indicator {
            // The `Border/Avatar/Indicator/Default` ring is bound as a filled circle
            // behind the indicator (the usual "punched-out ring" that separates a badge
            // from the avatar). This assumes a roughly circular indicator; a consumer
            // with a squared indicator can size its own view to suit.
            indicator
                .padding(indicatorRingWidth)
                .background(
                    Circle().fill(Color(viewConfig.color(.borderAvatarIndicatorDefault)))
                )
        }
    }

    // MARK: - Geometry

    /// Rounded → circle (radius = size/2); Squared → radius scales with size (4/8/16/24).
    private var cornerRadius: CGFloat {
        switch style {
        case .rounded: return size.points / 2
        case .squared:
            switch size {
            case .size16, .size24, .size28, .size32: return 4
            case .size40:                            return 8
            case .size56, .size64:                   return 16
            case .size120:                           return 24
            }
        }
    }

    private var clipShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    /// Person glyph inset. Spec calls for a fixed 10 pt inset per edge (glyph = size − 20);
    /// for the smallest sizes that would collapse, so we floor at 50% of the frame.
    private var glyphSize: CGFloat {
        max(size.points - 20, size.points * 0.5)
    }

    /// Initials scale with the avatar (~40% of the frame).
    private var initialsFontSize: CGFloat {
        max(size.points * 0.4, 8)
    }

    /// Ring thickness around the indicator, scaled to the avatar.
    private var indicatorRingWidth: CGFloat {
        max(size.points * 0.04, 1.5)
    }
}
