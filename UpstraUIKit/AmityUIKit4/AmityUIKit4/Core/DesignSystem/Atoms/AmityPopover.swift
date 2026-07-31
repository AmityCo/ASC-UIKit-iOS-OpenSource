//
//  AmityPopover.swift
//  AmityUIKit4
//
//  Design-system ATOM — the floating, trigger-anchored menu container.
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/Popover/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  Composite atom: owns the rounded container (surface + radius + elevation + the row
//  surface tokens); the rows are host-filled content. Row LABEL/ICON colours bind the
//  List atom's tokens (per spec), supplied by the row content, not this container.
//  Additive — the existing AmityPopoverMenu is untouched.
//

import SwiftUI

struct AmityPopover<Content: View>: View {

    private let width: CGFloat
    private let content: Content
    private let viewConfig: AmityViewConfigController

    /// - Parameter width: fixed instance width — 240 (create-chat / generic) or 160
    ///   (compact message-/media-pressed menus), per the spec's variant widths.
    init(width: CGFloat = 240,
         viewConfig: AmityViewConfigController,
         @ViewBuilder content: () -> Content) {
        self.width = width
        self.viewConfig = viewConfig
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.vertical, 8)               // container padding 8/0 — rows run edge-to-edge
        .frame(width: width)
        .background(Color(viewConfig.color(.surfacePopoverBackgroundDefault)))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        // Two-layer drop shadow authored in Figma; approximated with one soft shadow
        // (no elevation token exists in the registry — flagged in the DateTime/Sheet specs).
        .shadow(color: Color.black.opacity(0.16), radius: 4, y: 2)
    }
}

/// A single Popover row — background binds `Surface/Popover/Lists/*`; the caller supplies
/// the row content (leading glyph + label), which binds the List atom's Text/Icon tokens.
struct AmityPopoverRow<Content: View>: View {

    private let height: CGFloat
    private let isDisabled: Bool
    private let action: () -> Void
    private let content: Content
    private let viewConfig: AmityViewConfigController

    /// - Parameter height: 56 (create-chat rows) or 48 (message-/media-pressed rows).
    init(height: CGFloat = 56,
         isDisabled: Bool = false,
         viewConfig: AmityViewConfigController,
         action: @escaping () -> Void,
         @ViewBuilder content: () -> Content) {
        self.height = height
        self.isDisabled = isDisabled
        self.viewConfig = viewConfig
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                content
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .background(Color(viewConfig.color(isDisabled ? .surfacePopoverListsDisabled : .surfacePopoverListsDefault)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
