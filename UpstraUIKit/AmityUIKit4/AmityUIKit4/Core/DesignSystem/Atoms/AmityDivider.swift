//
//  AmityDivider.swift
//  AmityUIKit4
//
//  Design-system ATOM — the dividing-line primitive (Content vs Post) + optional inline label.
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/Divider/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  Conventions (see AmityToggle, the C1 pattern-setter):
//   • Presentational — no interaction, no internal state; renders straight from its inputs.
//   • Colours resolve through `viewConfig.color(_:)` (page/component-scoped theme).
//   • No icon (Divider has none per spec).
//   • Additive — this does not touch any existing component.
//

import SwiftUI

/// Line variant — governs which `Line/Divider/*` token the hairline binds and the default inset.
/// (The spec's `alphabet` variant is omitted: it has no token in the 3-token Divider model — see
/// the "Values to reconcile" note in the spec. Flagged as a gap, not silently reused.)
enum DividerVariantEnum {
    /// 1 px hairline, 16 pt horizontal inset — binds `Line/Divider/Content/Default`.
    case content
    /// 1 px edge-to-edge hairline — binds `Line/Divider/Post/Default`.
    case post
}

/// Line axis. Only `horizontal` is confirmed in the spec extraction; `vertical` is unconfirmed
/// (no instance in the Refining node or any consumer) and is rendered minimally, without label
/// support, pending design confirmation.
enum DividerOrientationEnum {
    case horizontal
    case vertical
}

/// Atomic dividing line — a 1 px hairline separator with an optional inline caption.
///
///     AmityDivider(variant: .post, viewConfig: viewConfig)
///     AmityDivider(variant: .content, label: "AND", viewConfig: viewConfig)
struct AmityDivider: View {

    private let variant: DividerVariantEnum
    private let orientation: DividerOrientationEnum
    private let inset: Bool
    private let label: String?
    private let viewConfig: AmityViewConfigController

    /// - Parameter inset: whether the line renders with the 16 pt horizontal inset. When omitted it
    ///   defaults to `true` for `.content` and `false` for `.post`, matching the per-variant spec
    ///   default (Content renders inset 0/16, Post renders edge-to-edge).
    init(variant: DividerVariantEnum,
         orientation: DividerOrientationEnum = .horizontal,
         inset: Bool? = nil,
         label: String? = nil,
         viewConfig: AmityViewConfigController) {
        self.variant = variant
        self.orientation = orientation
        self.inset = inset ?? (variant == .content)
        self.label = label
        self.viewConfig = viewConfig
    }

    // Geometry (spec): 1 px hairline; Content variant insets 16 pt from both horizontal edges.
    private let thickness: CGFloat = 1
    private let insetLength: CGFloat = 16
    private let labelGap: CGFloat = 8

    private var lineToken: AmityColorToken {
        variant == .content ? .lineDividerContentDefault : .lineDividerPostDefault
    }

    var body: some View {
        switch orientation {
        case .horizontal: horizontalBody
        case .vertical:   verticalBody
        }
    }

    // MARK: - Horizontal (confirmed)

    @ViewBuilder
    private var horizontalBody: some View {
        if let label, !label.isEmpty {
            // Labelled divider — the caption breaks the line; the hairline continues on either side.
            HStack(spacing: labelGap) {
                hairline
                Text(label)
                    .applyTextStyle(.caption(Color(viewConfig.color(.textDividerDefault))))
                    .fixedSize()
                hairline
            }
            .padding(.horizontal, inset ? insetLength : 0)
        } else {
            hairline
                .padding(.horizontal, inset ? insetLength : 0)
        }
    }

    private var hairline: some View {
        Rectangle()
            .fill(Color(viewConfig.color(lineToken)))
            .frame(height: thickness)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Vertical (unconfirmed — minimal, no label)

    private var verticalBody: some View {
        Rectangle()
            .fill(Color(viewConfig.color(lineToken)))
            .frame(width: thickness)
            .frame(maxHeight: .infinity)
    }
}
