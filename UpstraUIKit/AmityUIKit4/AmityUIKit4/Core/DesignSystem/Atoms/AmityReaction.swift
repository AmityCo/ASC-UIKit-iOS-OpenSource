//
//  AmityReaction.swift
//  AmityUIKit4
//
//  Design-system ATOM — the reaction family (glyph · group · count · popover).
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/Reaction/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  Owns the recolourable chrome (count-pill surface/border/text, popover surface, glyph
//  ring); the emoji discs themselves are fixed multi-colour assets supplied by the caller
//  (from MessageReactionConfiguration / SocialReactionConfiguration). Additive — the
//  existing reaction views (AmityReactionList / ChatReaction*) are untouched.
//

import SwiftUI

/// Which reaction primitive renders.
enum ReactionVariantEnum {
    case glyph   // a single reaction disc (recolourable separator ring)
    case group   // up to 5 discs overlapping in a fixed row
    case count   // a pill: group + numeric label (Chat Default/Active, or Post)
}

/// Count-pill text context.
enum ReactionContextEnum {
    case chat
    case post
}

/// Named `AmityReactionView` (not `AmityReaction`) — `AmityReaction` is an AmitySDK model.
struct AmityReactionView: View {

    private let variant: ReactionVariantEnum
    private let images: [ImageResource]
    private let glyphSize: CGFloat
    private let count: Int
    private let isActive: Bool
    private let context: ReactionContextEnum
    private let viewConfig: AmityViewConfigController

    init(variant: ReactionVariantEnum,
         images: [ImageResource],
         glyphSize: CGFloat = 20,
         count: Int = 0,
         isActive: Bool = false,
         context: ReactionContextEnum = .chat,
         viewConfig: AmityViewConfigController) {
        self.variant = variant
        self.images = images
        self.glyphSize = glyphSize
        self.count = count
        self.isActive = isActive
        self.context = context
        self.viewConfig = viewConfig
    }

    var body: some View {
        switch variant {
        case .glyph:
            glyphDisc(images.first, size: glyphSize)
        case .group:
            groupCluster
        case .count:
            countPill
        }
    }

    private func glyphDisc(_ image: ImageResource?, size: CGFloat) -> some View {
        Group {
            if let image {
                Image(image).resizable().scaledToFit()
            } else {
                Color.clear
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color(viewConfig.color(.borderReactionReactionAtomDefault)), lineWidth: 1))
    }

    // Up to 5 discs overlapping in a 20 px row.
    private var groupCluster: some View {
        HStack(spacing: -6) {
            ForEach(Array(images.prefix(5).enumerated()), id: \.offset) { _, img in
                glyphDisc(img, size: 20)
            }
        }
    }

    private var countPill: some View {
        let surfaceToken: AmityColorToken = isActive ? .surfaceReactionsReactionCountActive : .surfaceReactionsReactionCountDefault
        let borderToken: AmityColorToken = isActive ? .borderReactionReactionCountActive : .borderReactionReactionCountDefault
        let textToken: AmityColorToken
        switch context {
        case .chat: textToken = isActive ? .textReactionsChatReactionCountActive : .textReactionsChatReactionCountDefault
        case .post: textToken = .textReactionsPostReactionCountGeneral
        }
        return HStack(spacing: 4) {
            groupCluster
            Text("\(count)")
                .applyTextStyle(.caption(Color(viewConfig.color(textToken))))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(viewConfig.color(surfaceToken)))
        .overlay(Capsule().stroke(Color(viewConfig.color(borderToken)), lineWidth: 1))
        .clipShape(Capsule())
    }
}

/// Long-press quick-react picker container — a pill row of reaction items.
/// Owns the container surface (Filled = opaque Chat · Transparent = Live-stream chat);
/// the glyph items are host-supplied content.
struct AmityReactionPopover<Content: View>: View {

    enum Surface { case filled, transparent }

    private let surface: Surface
    private let content: Content
    private let viewConfig: AmityViewConfigController

    init(surface: Surface = .filled,
         viewConfig: AmityViewConfigController,
         @ViewBuilder content: () -> Content) {
        self.surface = surface
        self.viewConfig = viewConfig
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 8) {
            content
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(viewConfig.color(surface == .filled
                                           ? .surfaceReactionsReactionPopoverFilledDefault
                                           : .surfaceReactionsReactionPopoverTransparentDefault)))
        .clipShape(Capsule())
    }
}
