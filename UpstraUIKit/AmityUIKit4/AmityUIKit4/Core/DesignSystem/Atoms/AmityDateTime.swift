//
//  AmityDateTime.swift
//  AmityUIKit4
//
//  Design-system ATOM — the two non-interactive chat-timeline text primitives.
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/DateTime/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  Conventions (see AmityToggle / AmityDivider):
//   • Passive, non-interactive; no Hover/Press/Disabled state; renders straight from inputs.
//   • Colours resolve through `viewConfig.color(_:)`.
//   • Additive — does not touch any existing timeline/date views.
//
//  Callers supply the already-formatted string; this atom only styles it (the Figma
//  `Property 1` / `Format` variants document which pattern produced the text, they don't
//  change colour). The pill's authored drop-shadow is omitted: no elevation token exists.
//

import SwiftUI

/// Which timeline primitive renders.
enum DateTimeVariantEnum {
    case dateSeparator   // centered day pill ("Mon, 15 Jan"), radius 20 filled pill
    case timestamp       // bare time/date label (± "(edited)" suffix), no surface
}

struct AmityDateTime: View {

    private let variant: DateTimeVariantEnum
    private let text: String
    private let editedSuffix: String?
    private let viewConfig: AmityViewConfigController

    /// - Parameters:
    ///   - text: the pre-formatted date/time string.
    ///   - editedSuffix: `timestamp` only — an optional trailing suffix (e.g. "(edited)"),
    ///     rendered after a 2 pt gap in the same token. Ignored for `dateSeparator`.
    init(variant: DateTimeVariantEnum,
         text: String,
         editedSuffix: String? = nil,
         viewConfig: AmityViewConfigController) {
        self.variant = variant
        self.text = text
        self.editedSuffix = editedSuffix
        self.viewConfig = viewConfig
    }

    var body: some View {
        switch variant {
        case .dateSeparator:
            Text(text)
                .applyTextStyle(.caption(Color(viewConfig.color(.textDateAndTimeDateSeparatorDefault))))
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(viewConfig.color(.surfaceDateAndTimeDateSeparatorDefault)))
                .clipShape(RoundedRectangle(cornerRadius: 20))

        case .timestamp:
            HStack(spacing: 2) {
                Text(text)
                    .applyTextStyle(.caption(Color(viewConfig.color(.textTimestampDefault))))
                if let editedSuffix {
                    Text(editedSuffix)
                        .applyTextStyle(.caption(Color(viewConfig.color(.textTimestampDefault))))
                }
            }
        }
    }
}
