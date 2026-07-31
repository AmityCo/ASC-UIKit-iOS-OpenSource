//
//  AmityButton.swift
//  AmityUIKit4
//
//  Design-system ATOM — the button family (Main / Icon / Square).
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/Button/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  Follows the conventions set by AmityToggle (the C1 pattern-setter):
//   • Presentational + controlled — the consumer owns behaviour; the atom only reports
//     activation via `onClick`. Only `variant` + config props + `disabled` are inputs.
//   • Colours resolve through `viewConfig.color(_:)` (page/component-scoped theme).
//   • Icons come from `AmityIcon.DesignSystem` (template-rendered, tinted by an Icon/* token).
//   • Interaction state (pressed/disabled) is resolved INTERNALLY through a private
//     `ButtonStyle` (same idiom as AmityToggle / AmityButtonStyle), using
//     `@Environment(\.isEnabled)` + `configuration.isPressed`.
//   • ADDITIVE — this is a NEW atom. It does NOT touch the existing, Social-shared
//     `AmityButtonStyle` (Primary/Line/DropDown/Selection). Both coexist.
//
//  ── iOS press-state mapping ────────────────────────────────────────────────────────
//  The token grammar carries a `Hover` state that iOS has no pointer for. We map the
//  three real iOS states to the authored token states:
//      enabled  → Enabled  (Main / Icon-surface) · Default (Icon-glyph / Square)
//      pressed  → Hover    (Main / Icon-surface / Square) · Hovered (Icon-glyph)
//      disabled → Disabled
//  i.e. the `Hover` (a.k.a. `Hovered`) token doubles as the iOS pressed appearance —
//  there is no distinct `Pressed` token in the export.
//
//  ── Scope / gaps (see spec §"State → token" + decomposition §4/§6) ──────────────────
//   • Implemented in v1: variant `main`, `icon`, `square` — the three sub-components that
//     have a documented colors-v2 token grammar (281 tokens grepped from the generated
//     enum; the source spec cites 288 incl. the ~7 ActionButton/split/fab tokens we skip).
//   • OMITTED from v1: `fab`, `split`, `reaction`. The spec has Geometry only and NO token
//     grammar for these ("no documented token grammar yet — Geometry only — so their token
//     resolution is a gap to reconcile in this file first"). Rather than fabricate tokens,
//     they are left out of `ButtonVariantEnum` entirely; add them once the grammar lands.
//   • Ghost (spec C9 → "option A", 2026-07-14): the Ghost `/Hover` surface & border are a web-only
//     pointer affordance. On iOS ghost is fully transparent in EVERY state (no fill, no border) —
//     rest AND pressed both resolve surface/border → `nil` → clear. Press feedback comes from the
//     text/icon Hover tint + the native affordance, not a surface tint.
//   • Transparent (Main) surface has Default/Primary only (no Secondary, no Destructive). Its Border
//     (Default/Primary) landed in the 2026-07-14 Semantic re-export and is now wired below.
//     Link / Description (Main) have Text + Icon tokens but NO Surface/Border (they render with no
//     fill). Inverse (Main) Secondary Border also landed in that re-export (wired below). Any prop
//     combination that lands on a non-existent token resolves to `nil` and falls back (surface →
//     clear, border → none, text/icon → the Filled/Primary token of the same colour+state).
//   • Authored state-name inconsistency preserved as-is: Main/Square Surface use
//     `Enabled`/`Hover`; Icon glyph uses `Default`/`Hovered`; Square uses `Default`/`Hover`.
//

import SwiftUI

// MARK: - Public enums (from spec API Reference)

/// Which button sub-component this instance renders. v1 implements the three token-backed
/// families; `fab`/`split`/`reaction` are intentionally omitted (no token grammar yet).
enum ButtonVariantEnum {
    case main    // Main Button — text (± icon) CTA, the largest matrix
    case icon    // Icon Button — icon-only, round, sized 16–64pt
    case square  // Square Button — vertical icon-over-label action (swipe/toolbar)
}

/// Token grammar's `Color` axis. Only meaningful on `.main` and `.square`.
enum ButtonColorEnum {
    case `default`
    case destructive
}

/// Token grammar's `Hierarchy` axis. `.general` exists on Icon Button only.
enum ButtonHierarchyEnum {
    case primary
    case secondary
    case general
}

/// Token grammar's `Type` axis (the surface treatment). Full 7-value set applies to
/// `.main`; `filled`/`ghost`/`transparent`/`label` apply to `.icon`; ignored by `.square`.
enum ButtonStyleEnum {
    case filled
    case outlined
    case ghost
    case inverse
    case link
    case description
    case transparent
    case label
}

/// Main Button size (spec Geometry): lg = 40pt box, sm = 28pt box.
enum MainButtonSizeEnum {
    case lg
    case sm
}

/// Icon Button size (spec Geometry). Raw value is the square edge in points.
enum IconButtonSizeEnum: Int {
    case size16 = 16
    case size20 = 20
    case size24 = 24
    case size32 = 32
    case size40 = 40
    case size48 = 48
    case size64 = 64
}

// MARK: - AmityButton

/// The design-system Button atom. `variant` selects the sub-component and fixes which of
/// the other props apply (see per-prop notes in the spec).
///
///     AmityButton(variant: .main, style: .filled, label: "Create new chat",
///                 icon: .plusR, viewConfig: viewConfig) {
///         viewModel.createChat()
///     }
struct AmityButton: View {

    private let variant: ButtonVariantEnum
    private let color: ButtonColorEnum
    private let hierarchy: ButtonHierarchyEnum
    private let style: ButtonStyleEnum
    private let mainSize: MainButtonSizeEnum
    private let iconSize: IconButtonSizeEnum
    private let label: String?
    private let icon: AmityIcon.DesignSystem?
    private let isDisabled: Bool
    private let onClick: () -> Void
    private let viewConfig: AmityViewConfigController

    /// - Parameters:
    ///   - variant: required sub-component discriminator.
    ///   - color: Default/Destructive (main & square only).
    ///   - hierarchy: Primary/Secondary (+ General on icon).
    ///   - style: the `Type` axis surface treatment (subset valid per variant).
    ///   - mainSize / iconSize: size enum for the relevant variant (spec uses a union type;
    ///     iOS splits it into the two size axes that carry geometry). Square is fixed 80×82.
    ///   - label: text slot (main / square; ignored by icon unless `style == .label`).
    ///   - icon: leading/sole glyph, drawn template-mode and tinted by the Icon/* token.
    ///   - isDisabled: resolves the Disabled token slice; blocks `onClick`.
    ///   - onClick: activation callback (not called while disabled).
    init(variant: ButtonVariantEnum,
         color: ButtonColorEnum = .default,
         hierarchy: ButtonHierarchyEnum = .primary,
         style: ButtonStyleEnum = .filled,
         mainSize: MainButtonSizeEnum = .lg,
         iconSize: IconButtonSizeEnum = .size40,
         label: String? = nil,
         icon: AmityIcon.DesignSystem? = nil,
         isDisabled: Bool = false,
         viewConfig: AmityViewConfigController,
         onClick: @escaping () -> Void) {
        self.variant = variant
        self.color = color
        self.hierarchy = hierarchy
        self.style = style
        self.mainSize = mainSize
        self.iconSize = iconSize
        self.label = label
        self.icon = icon
        self.isDisabled = isDisabled
        self.viewConfig = viewConfig
        self.onClick = onClick
    }

    var body: some View {
        Group {
            switch variant {
            case .main:
                Button(action: onClick) { EmptyView() }
                    .buttonStyle(AmityMainButtonRenderStyle(
                        color: color, style: style, hierarchy: hierarchy, size: mainSize,
                        label: label, icon: icon, viewConfig: viewConfig))
            case .icon:
                Button(action: onClick) { EmptyView() }
                    .buttonStyle(AmityIconButtonRenderStyle(
                        style: style, hierarchy: hierarchy, size: iconSize,
                        label: label, icon: icon, viewConfig: viewConfig))
            case .square:
                Button(action: onClick) { EmptyView() }
                    .buttonStyle(AmitySquareButtonRenderStyle(
                        color: color, hierarchy: hierarchy,
                        label: label, icon: icon, viewConfig: viewConfig))
            }
        }
        .disabled(isDisabled)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text(label ?? ""))
    }
}

// MARK: - Shared interaction state

/// The three iOS-real states. `pressed` stands in for the token grammar's Hover/Hovered.
private enum ButtonInteractionState {
    case enabled, pressed, disabled

    static func resolve(isEnabled: Bool, isPressed: Bool) -> ButtonInteractionState {
        !isEnabled ? .disabled : (isPressed ? .pressed : .enabled)
    }
}

// MARK: - Main Button render style

private struct AmityMainButtonRenderStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    let color: ButtonColorEnum
    let style: ButtonStyleEnum
    let hierarchy: ButtonHierarchyEnum
    let size: MainButtonSizeEnum
    let label: String?
    let icon: AmityIcon.DesignSystem?
    let viewConfig: AmityViewConfigController

    private var isSmall: Bool { size == .sm }
    private var isLink: Bool { style == .link }
    private var isDescription: Bool { style == .description }
    private var hasLabel: Bool { !(label ?? "").isEmpty }

    func makeBody(configuration: Configuration) -> some View {
        let state = ButtonInteractionState.resolve(isEnabled: isEnabled, isPressed: configuration.isPressed)

        // Geometry (spec Geometry table).
        let gap: CGFloat = isSmall ? 4 : 8
        let glyphSize: CGFloat = isSmall ? 16 : 20
        // radius: lg = 8; sm = 6 — except Transparent/sm which the spec extracts as 8.
        // Link/Description have no filled surface → nothing to round.
        let radius: CGFloat = (isLink || isDescription)
            ? 0
            : (isSmall ? (style == .transparent ? 8 : 6) : 8)

        let textToken = mainTextToken(color, style, hierarchy, state)
            ?? mainTextToken(color, .filled, .primary, state)
            ?? .textMainButtonDefaultFilledPrimaryEnabled
        let iconToken = mainIconToken(color, style, hierarchy, state)
            ?? mainIconToken(color, .filled, .primary, state)
            ?? .iconMainButtonDefaultFilledPrimaryEnabled
        let labelColor = Color(viewConfig.color(textToken))

        return content(glyphSize: glyphSize, gap: gap, iconToken: iconToken, labelColor: labelColor)
            .background(surface(state))
            .overlay(borderOverlay(state, radius: radius))
            .cornerRadius(radius)
            .contentShape(Rectangle())
    }

    @ViewBuilder
    private func content(glyphSize: CGFloat, gap: CGFloat, iconToken: AmityColorToken, labelColor: Color) -> some View {
        // Icon-only: fixed square box (lg 40×40 / sm 28×28), no label.
        if !hasLabel {
            let edge: CGFloat = isLink ? (isSmall ? 16 : 20) : (isSmall ? 28 : 40)
            glyphView(size: glyphSize, token: iconToken)
                .frame(width: edge, height: edge)
        } else {
            let vPad: CGFloat = isLink ? 0 : (isSmall ? 4 : 10)
            let hPad: CGFloat = isLink ? 0 : (isSmall ? 8 : 12)
            let minHeight: CGFloat = isLink ? (isSmall ? 16 : 20) : (isSmall ? 28 : 40)
            HStack(spacing: gap) {
                if icon != nil {
                    glyphView(size: glyphSize, token: iconToken)
                }
                Text(label ?? "")
                    .applyTextStyle(labelTextStyle(labelColor))
            }
            .padding(.vertical, vPad)
            .padding(.horizontal, hPad)
            .frame(minHeight: minHeight)
        }
    }

    @ViewBuilder
    private func glyphView(size: CGFloat, token: AmityColorToken) -> some View {
        if let icon {
            Image(icon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundColor(Color(viewConfig.color(token)))
        }
    }

    private func labelTextStyle(_ color: Color) -> AmityTextStyle {
        isSmall ? .captionBold(color) : .bodyBold(color)
    }

    /// Surface fill. `nil` token (ghost resting, link, description, transparent-secondary…)
    /// → transparent (spec C9 fallback).
    @ViewBuilder
    private func surface(_ state: ButtonInteractionState) -> some View {
        if let token = mainSurfaceToken(color, style, hierarchy, state) {
            Color(viewConfig.color(token))
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private func borderOverlay(_ state: ButtonInteractionState, radius: CGFloat) -> some View {
        if let token = mainBorderToken(color, style, hierarchy, state) {
            RoundedRectangle(cornerRadius: radius)
                .stroke(Color(viewConfig.color(token)), lineWidth: 1)
        }
    }
}

// MARK: - Icon Button render style

private struct AmityIconButtonRenderStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    let style: ButtonStyleEnum
    let hierarchy: ButtonHierarchyEnum
    let size: IconButtonSizeEnum
    let label: String?
    let icon: AmityIcon.DesignSystem?
    let viewConfig: AmityViewConfigController

    func makeBody(configuration: Configuration) -> some View {
        let state = ButtonInteractionState.resolve(isEnabled: isEnabled, isPressed: configuration.isPressed)
        let edge = CGFloat(size.rawValue)
        let padding = iconPadding(edge: edge)
        let glyphSize = max(edge - padding * 2, 0)

        // Glyph tint. `.label` style has only the General text token → use it for the glyph too.
        let glyphToken: AmityColorToken = (style == .label)
            ? .textIconButtonLabelGeneral
            : (iconGlyphToken(style, hierarchy, state)
                ?? iconGlyphToken(.filled, .primary, state)
                ?? .iconIconButtonFilledPrimaryDefault)

        return HStack(spacing: 8) {
            if let icon {
                Image(icon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: glyphSize, height: glyphSize)
                    .foregroundColor(Color(viewConfig.color(glyphToken)))
            }
            // `label` style is the one Icon-Button type that carries text.
            if style == .label, let label, !label.isEmpty {
                Text(label)
                    .applyTextStyle(.bodyBold(Color(viewConfig.color(.textIconButtonLabelGeneral))))
            }
        }
        .frame(width: style == .label ? nil : edge, height: edge)
        .background(surface(state))
        .clipShape(Capsule())  // radius 99 pill
        .contentShape(Capsule())
    }

    /// Inset per size (spec Geometry): 16/20/24 → 0; 32 → 4; 40 → 4 (transparent) / 8 (filled);
    /// 48 → 8; 64 → 16.
    private func iconPadding(edge: CGFloat) -> CGFloat {
        switch size {
        case .size16, .size20, .size24: return 0
        case .size32: return 4
        case .size40: return style == .transparent ? 4 : 8
        case .size48: return 8
        case .size64: return 16
        }
    }

    /// Surface fill. Ghost resting → transparent (spec C9); label → transparent (no surface token).
    @ViewBuilder
    private func surface(_ state: ButtonInteractionState) -> some View {
        if style != .label, let token = iconSurfaceToken(style, hierarchy, state) {
            Color(viewConfig.color(token))
        } else {
            Color.clear
        }
    }
}

// MARK: - Square Button render style

private struct AmitySquareButtonRenderStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    let color: ButtonColorEnum
    let hierarchy: ButtonHierarchyEnum
    let label: String?
    let icon: AmityIcon.DesignSystem?
    let viewConfig: AmityViewConfigController

    // Fixed geometry (spec): 80×82, pad 16/8, gap 4, vertical icon-over-label, radius "—" → 0.
    private let width: CGFloat = 80
    private let height: CGFloat = 82
    private let glyphSize: CGFloat = 24

    func makeBody(configuration: Configuration) -> some View {
        let state = ButtonInteractionState.resolve(isEnabled: isEnabled, isPressed: configuration.isPressed)

        let iconToken = squareIconToken(color, hierarchy, state)
            ?? squareIconToken(.default, .primary, state)
            ?? .iconSquareButtonDefaultPrimaryDefault
        let textToken = squareTextToken(color, hierarchy, state)
            ?? squareTextToken(.default, .primary, state)
            ?? .textSquareButtonDefaultPrimaryDefault

        return VStack(spacing: 4) {
            if let icon {
                Image(icon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: glyphSize, height: glyphSize)
                    .foregroundColor(Color(viewConfig.color(iconToken)))
            }
            if let label, !label.isEmpty {
                Text(label)
                    .applyTextStyle(.caption(Color(viewConfig.color(textToken))))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .frame(width: width, height: height)
        .background(surface(state))
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func surface(_ state: ButtonInteractionState) -> some View {
        if let token = squareSurfaceToken(color, hierarchy, state) {
            Color(viewConfig.color(token))
        } else {
            Color.clear
        }
    }
}

// MARK: - Token resolution
//
// Every arm below is generated verbatim from AmityColorTokens.generated.swift — the case
// identifiers are copied from the real enum, so an incorrect name is a compile error, and
// combinations with no authored token return `nil` (handled by the render styles' fallbacks).

/// `{Surface}/MainButton/{Color}/{Type}/{Hierarchy}/{State}`
private func mainSurfaceToken(_ color: ButtonColorEnum, _ style: ButtonStyleEnum, _ hierarchy: ButtonHierarchyEnum, _ state: ButtonInteractionState) -> AmityColorToken? {
    switch (color, style, hierarchy, state) {
    case (.default, .filled, .primary, .enabled): return .surfaceMainButtonDefaultFilledPrimaryEnabled
    case (.default, .filled, .primary, .pressed): return .surfaceMainButtonDefaultFilledPrimaryHover
    case (.default, .filled, .primary, .disabled): return .surfaceMainButtonDefaultFilledPrimaryDisabled
    case (.default, .filled, .secondary, .enabled): return .surfaceMainButtonDefaultFilledSecondaryEnabled
    case (.default, .filled, .secondary, .pressed): return .surfaceMainButtonDefaultFilledSecondaryHover
    case (.default, .filled, .secondary, .disabled): return .surfaceMainButtonDefaultFilledSecondaryDisabled
    case (.default, .outlined, .primary, .enabled): return .surfaceMainButtonDefaultOutlinedPrimaryEnabled
    case (.default, .outlined, .primary, .pressed): return .surfaceMainButtonDefaultOutlinedPrimaryHover
    case (.default, .outlined, .primary, .disabled): return .surfaceMainButtonDefaultOutlinedPrimaryDisabled
    case (.default, .outlined, .secondary, .enabled): return .surfaceMainButtonDefaultOutlinedSecondaryEnabled
    case (.default, .outlined, .secondary, .pressed): return .surfaceMainButtonDefaultOutlinedSecondaryHover
    case (.default, .outlined, .secondary, .disabled): return .surfaceMainButtonDefaultOutlinedSecondaryDisabled
    // Ghost: NO iOS surface binding (spec "option A", 2026-07-14). The Ghost `/Hover` surface is a
    // web-only pointer affordance; on iOS ghost stays transparent in every state (rest → clear per C9,
    // press → clear too). Press feedback comes from the text/icon Hover tint + the native affordance,
    // not a surface tint. Same rationale applies to the ghost border arms and IconButton ghost below.
    case (.default, .inverse, .primary, .enabled): return .surfaceMainButtonDefaultInversePrimaryEnabled
    case (.default, .inverse, .primary, .pressed): return .surfaceMainButtonDefaultInversePrimaryHover
    case (.default, .inverse, .primary, .disabled): return .surfaceMainButtonDefaultInversePrimaryDisabled
    case (.default, .inverse, .secondary, .enabled): return .surfaceMainButtonDefaultInverseSecondaryEnabled
    case (.default, .inverse, .secondary, .pressed): return .surfaceMainButtonDefaultInverseSecondaryHover
    case (.default, .inverse, .secondary, .disabled): return .surfaceMainButtonDefaultInverseSecondaryDisabled
    case (.default, .transparent, .primary, .enabled): return .surfaceMainButtonDefaultTransparentPrimaryEnabled
    case (.default, .transparent, .primary, .pressed): return .surfaceMainButtonDefaultTransparentPrimaryHover
    case (.default, .transparent, .primary, .disabled): return .surfaceMainButtonDefaultTransparentPrimaryDisabled
    case (.destructive, .filled, .primary, .enabled): return .surfaceMainButtonDestructiveFilledPrimaryEnabled
    case (.destructive, .filled, .primary, .pressed): return .surfaceMainButtonDestructiveFilledPrimaryHover
    case (.destructive, .filled, .primary, .disabled): return .surfaceMainButtonDestructiveFilledPrimaryDisabled
    case (.destructive, .filled, .secondary, .enabled): return .surfaceMainButtonDestructiveFilledSecondaryEnabled
    case (.destructive, .filled, .secondary, .pressed): return .surfaceMainButtonDestructiveFilledSecondaryHover
    case (.destructive, .filled, .secondary, .disabled): return .surfaceMainButtonDestructiveFilledSecondaryDisabled
    case (.destructive, .outlined, .primary, .enabled): return .surfaceMainButtonDestructiveOutlinedPrimaryEnabled
    case (.destructive, .outlined, .primary, .pressed): return .surfaceMainButtonDestructiveOutlinedPrimaryHover
    case (.destructive, .outlined, .primary, .disabled): return .surfaceMainButtonDestructiveOutlinedPrimaryDisabled
    case (.destructive, .outlined, .secondary, .enabled): return .surfaceMainButtonDestructiveOutlinedSecondaryEnabled
    case (.destructive, .outlined, .secondary, .pressed): return .surfaceMainButtonDestructiveOutlinedSecondaryHover
    case (.destructive, .outlined, .secondary, .disabled): return .surfaceMainButtonDestructiveOutlinedSecondaryDisabled
    // Ghost destructive: no iOS surface binding (spec "option A") — see the ghost note above.
    case (.destructive, .inverse, .primary, .enabled): return .surfaceMainButtonDestructiveInversePrimaryEnabled
    case (.destructive, .inverse, .primary, .pressed): return .surfaceMainButtonDestructiveInversePrimaryHover
    case (.destructive, .inverse, .primary, .disabled): return .surfaceMainButtonDestructiveInversePrimaryDisabled
    case (.destructive, .inverse, .secondary, .enabled): return .surfaceMainButtonDestructiveInverseSecondaryEnabled
    case (.destructive, .inverse, .secondary, .pressed): return .surfaceMainButtonDestructiveInverseSecondaryHover
    case (.destructive, .inverse, .secondary, .disabled): return .surfaceMainButtonDestructiveInverseSecondaryDisabled
    default: return nil
    }
}

/// `{Border}/MainButton/{Color}/{Type}/{Hierarchy}/{State}`
private func mainBorderToken(_ color: ButtonColorEnum, _ style: ButtonStyleEnum, _ hierarchy: ButtonHierarchyEnum, _ state: ButtonInteractionState) -> AmityColorToken? {
    switch (color, style, hierarchy, state) {
    case (.default, .filled, .primary, .enabled): return .borderMainButtonDefaultFilledPrimaryEnabled
    case (.default, .filled, .primary, .pressed): return .borderMainButtonDefaultFilledPrimaryHover
    case (.default, .filled, .primary, .disabled): return .borderMainButtonDefaultFilledPrimaryDisabled
    case (.default, .filled, .secondary, .enabled): return .borderMainButtonDefaultFilledSecondaryEnabled
    case (.default, .filled, .secondary, .pressed): return .borderMainButtonDefaultFilledSecondaryHover
    case (.default, .filled, .secondary, .disabled): return .borderMainButtonDefaultFilledSecondaryDisabled
    case (.default, .outlined, .primary, .enabled): return .borderMainButtonDefaultOutlinedPrimaryEnabled
    case (.default, .outlined, .primary, .pressed): return .borderMainButtonDefaultOutlinedPrimaryHover
    case (.default, .outlined, .primary, .disabled): return .borderMainButtonDefaultOutlinedPrimaryDisabled
    case (.default, .outlined, .secondary, .enabled): return .borderMainButtonDefaultOutlinedSecondaryEnabled
    case (.default, .outlined, .secondary, .pressed): return .borderMainButtonDefaultOutlinedSecondaryHover
    case (.default, .outlined, .secondary, .disabled): return .borderMainButtonDefaultOutlinedSecondaryDisabled
    // Ghost: no iOS border binding (spec "option A") — ghost is fully transparent on iOS (no fill, no
    // border) in every state; the `/Hover` border was part of the web-only hover affordance.
    case (.default, .inverse, .primary, .enabled): return .borderMainButtonDefaultInversePrimaryEnabled
    case (.default, .inverse, .primary, .pressed): return .borderMainButtonDefaultInversePrimaryHover
    case (.default, .inverse, .primary, .disabled): return .borderMainButtonDefaultInversePrimaryDisabled
    // Border/MainButton/Default/Inverse/Secondary + Default/Transparent/Primary — added by the
    // 2026-07-14 Semantic re-export (previously nil-fallback); now bound so the matrix is complete.
    case (.default, .inverse, .secondary, .enabled): return .borderMainButtonDefaultInverseSecondaryEnabled
    case (.default, .inverse, .secondary, .pressed): return .borderMainButtonDefaultInverseSecondaryHover
    case (.default, .inverse, .secondary, .disabled): return .borderMainButtonDefaultInverseSecondaryDisabled
    case (.default, .transparent, .primary, .enabled): return .borderMainButtonDefaultTransparentPrimaryEnabled
    case (.default, .transparent, .primary, .pressed): return .borderMainButtonDefaultTransparentPrimaryHover
    case (.default, .transparent, .primary, .disabled): return .borderMainButtonDefaultTransparentPrimaryDisabled
    case (.destructive, .filled, .primary, .enabled): return .borderMainButtonDestructiveFilledPrimaryEnabled
    case (.destructive, .filled, .primary, .pressed): return .borderMainButtonDestructiveFilledPrimaryHover
    case (.destructive, .filled, .primary, .disabled): return .borderMainButtonDestructiveFilledPrimaryDisabled
    case (.destructive, .filled, .secondary, .enabled): return .borderMainButtonDestructiveFilledSecondaryEnabled
    case (.destructive, .filled, .secondary, .pressed): return .borderMainButtonDestructiveFilledSecondaryHover
    case (.destructive, .filled, .secondary, .disabled): return .borderMainButtonDestructiveFilledSecondaryDisabled
    case (.destructive, .outlined, .primary, .enabled): return .borderMainButtonDestructiveOutlinedPrimaryEnabled
    case (.destructive, .outlined, .primary, .pressed): return .borderMainButtonDestructiveOutlinedPrimaryHover
    case (.destructive, .outlined, .primary, .disabled): return .borderMainButtonDestructiveOutlinedPrimaryDisabled
    case (.destructive, .outlined, .secondary, .enabled): return .borderMainButtonDestructiveOutlinedSecondaryEnabled
    case (.destructive, .outlined, .secondary, .pressed): return .borderMainButtonDestructiveOutlinedSecondaryHover
    case (.destructive, .outlined, .secondary, .disabled): return .borderMainButtonDestructiveOutlinedSecondaryDisabled
    // Ghost destructive: no iOS border binding (spec "option A") — see the ghost note above.
    case (.destructive, .inverse, .primary, .enabled): return .borderMainButtonDestructiveInversePrimaryEnabled
    case (.destructive, .inverse, .primary, .pressed): return .borderMainButtonDestructiveInversePrimaryHover
    case (.destructive, .inverse, .primary, .disabled): return .borderMainButtonDestructiveInversePrimaryDisabled
    // Border/MainButton/Destructive/Inverse/Secondary — added by the 2026-07-14 Semantic re-export.
    case (.destructive, .inverse, .secondary, .enabled): return .borderMainButtonDestructiveInverseSecondaryEnabled
    case (.destructive, .inverse, .secondary, .pressed): return .borderMainButtonDestructiveInverseSecondaryHover
    case (.destructive, .inverse, .secondary, .disabled): return .borderMainButtonDestructiveInverseSecondaryDisabled
    default: return nil
    }
}

/// `{Text}/MainButton/{Color}/{Type}/{Hierarchy}/{State}`
private func mainTextToken(_ color: ButtonColorEnum, _ style: ButtonStyleEnum, _ hierarchy: ButtonHierarchyEnum, _ state: ButtonInteractionState) -> AmityColorToken? {
    switch (color, style, hierarchy, state) {
    case (.default, .filled, .primary, .enabled): return .textMainButtonDefaultFilledPrimaryEnabled
    case (.default, .filled, .primary, .pressed): return .textMainButtonDefaultFilledPrimaryHover
    case (.default, .filled, .primary, .disabled): return .textMainButtonDefaultFilledPrimaryDisabled
    case (.default, .filled, .secondary, .enabled): return .textMainButtonDefaultFilledSecondaryEnabled
    case (.default, .filled, .secondary, .pressed): return .textMainButtonDefaultFilledSecondaryHover
    case (.default, .filled, .secondary, .disabled): return .textMainButtonDefaultFilledSecondaryDisabled
    case (.default, .outlined, .primary, .enabled): return .textMainButtonDefaultOutlinedPrimaryEnabled
    case (.default, .outlined, .primary, .pressed): return .textMainButtonDefaultOutlinedPrimaryHover
    case (.default, .outlined, .primary, .disabled): return .textMainButtonDefaultOutlinedPrimaryDisabled
    case (.default, .outlined, .secondary, .enabled): return .textMainButtonDefaultOutlinedSecondaryEnabled
    case (.default, .outlined, .secondary, .pressed): return .textMainButtonDefaultOutlinedSecondaryHover
    case (.default, .outlined, .secondary, .disabled): return .textMainButtonDefaultOutlinedSecondaryDisabled
    case (.default, .ghost, .primary, .enabled): return .textMainButtonDefaultGhostPrimaryEnabled
    case (.default, .ghost, .primary, .pressed): return .textMainButtonDefaultGhostPrimaryHover
    case (.default, .ghost, .primary, .disabled): return .textMainButtonDefaultGhostPrimaryDisabled
    case (.default, .ghost, .secondary, .enabled): return .textMainButtonDefaultGhostSecondaryEnabled
    case (.default, .ghost, .secondary, .pressed): return .textMainButtonDefaultGhostSecondaryHover
    case (.default, .ghost, .secondary, .disabled): return .textMainButtonDefaultGhostSecondaryDisabled
    case (.default, .inverse, .primary, .enabled): return .textMainButtonDefaultInversePrimaryEnabled
    case (.default, .inverse, .primary, .pressed): return .textMainButtonDefaultInversePrimaryHover
    case (.default, .inverse, .primary, .disabled): return .textMainButtonDefaultInversePrimaryDisabled
    case (.default, .inverse, .secondary, .enabled): return .textMainButtonDefaultInverseSecondaryEnabled
    case (.default, .inverse, .secondary, .pressed): return .textMainButtonDefaultInverseSecondaryHover
    case (.default, .inverse, .secondary, .disabled): return .textMainButtonDefaultInverseSecondaryDisabled
    case (.default, .link, .primary, .enabled): return .textMainButtonDefaultLinkPrimaryEnabled
    case (.default, .link, .primary, .pressed): return .textMainButtonDefaultLinkPrimaryHover
    case (.default, .link, .primary, .disabled): return .textMainButtonDefaultLinkPrimaryDisabled
    case (.default, .link, .secondary, .enabled): return .textMainButtonDefaultLinkSecondaryEnabled
    case (.default, .link, .secondary, .pressed): return .textMainButtonDefaultLinkSecondaryHover
    case (.default, .link, .secondary, .disabled): return .textMainButtonDefaultLinkSecondaryDisabled
    case (.default, .description, .primary, .enabled): return .textMainButtonDefaultDescriptionPrimaryEnabled
    case (.default, .description, .primary, .pressed): return .textMainButtonDefaultDescriptionPrimaryHover
    case (.default, .description, .primary, .disabled): return .textMainButtonDefaultDescriptionPrimaryDisabled
    case (.default, .description, .secondary, .enabled): return .textMainButtonDefaultDescriptionSecondaryEnabled
    case (.default, .description, .secondary, .pressed): return .textMainButtonDefaultDescriptionSecondaryHover
    case (.default, .description, .secondary, .disabled): return .textMainButtonDefaultDescriptionSecondaryDisabled
    case (.default, .transparent, .primary, .enabled): return .textMainButtonDefaultTransparentPrimaryEnabled
    case (.default, .transparent, .primary, .pressed): return .textMainButtonDefaultTransparentPrimaryHover
    case (.default, .transparent, .primary, .disabled): return .textMainButtonDefaultTransparentPrimaryDisabled
    case (.destructive, .filled, .primary, .enabled): return .textMainButtonDestructiveFilledPrimaryEnabled
    case (.destructive, .filled, .primary, .pressed): return .textMainButtonDestructiveFilledPrimaryHover
    case (.destructive, .filled, .primary, .disabled): return .textMainButtonDestructiveFilledPrimaryDisabled
    case (.destructive, .filled, .secondary, .enabled): return .textMainButtonDestructiveFilledSecondaryEnabled
    case (.destructive, .filled, .secondary, .pressed): return .textMainButtonDestructiveFilledSecondaryHover
    case (.destructive, .filled, .secondary, .disabled): return .textMainButtonDestructiveFilledSecondaryDisabled
    case (.destructive, .outlined, .primary, .enabled): return .textMainButtonDestructiveOutlinedPrimaryEnabled
    case (.destructive, .outlined, .primary, .pressed): return .textMainButtonDestructiveOutlinedPrimaryHover
    case (.destructive, .outlined, .primary, .disabled): return .textMainButtonDestructiveOutlinedPrimaryDisabled
    case (.destructive, .outlined, .secondary, .enabled): return .textMainButtonDestructiveOutlinedSecondaryEnabled
    case (.destructive, .outlined, .secondary, .pressed): return .textMainButtonDestructiveOutlinedSecondaryHover
    case (.destructive, .outlined, .secondary, .disabled): return .textMainButtonDestructiveOutlinedSecondaryDisabled
    case (.destructive, .ghost, .primary, .enabled): return .textMainButtonDestructiveGhostPrimaryEnabled
    case (.destructive, .ghost, .primary, .pressed): return .textMainButtonDestructiveGhostPrimaryHover
    case (.destructive, .ghost, .primary, .disabled): return .textMainButtonDestructiveGhostPrimaryDisabled
    case (.destructive, .ghost, .secondary, .enabled): return .textMainButtonDestructiveGhostSecondaryEnabled
    case (.destructive, .ghost, .secondary, .pressed): return .textMainButtonDestructiveGhostSecondaryHover
    case (.destructive, .ghost, .secondary, .disabled): return .textMainButtonDestructiveGhostSecondaryDisabled
    case (.destructive, .inverse, .primary, .enabled): return .textMainButtonDestructiveInversePrimaryEnabled
    case (.destructive, .inverse, .primary, .pressed): return .textMainButtonDestructiveInversePrimaryHover
    case (.destructive, .inverse, .primary, .disabled): return .textMainButtonDestructiveInversePrimaryDisabled
    case (.destructive, .inverse, .secondary, .enabled): return .textMainButtonDestructiveInverseSecondaryEnabled
    case (.destructive, .inverse, .secondary, .pressed): return .textMainButtonDestructiveInverseSecondaryHover
    case (.destructive, .inverse, .secondary, .disabled): return .textMainButtonDestructiveInverseSecondaryDisabled
    case (.destructive, .link, .primary, .enabled): return .textMainButtonDestructiveLinkPrimaryEnabled
    case (.destructive, .link, .primary, .pressed): return .textMainButtonDestructiveLinkPrimaryHover
    case (.destructive, .link, .primary, .disabled): return .textMainButtonDestructiveLinkPrimaryDisabled
    case (.destructive, .link, .secondary, .enabled): return .textMainButtonDestructiveLinkSecondaryEnabled
    case (.destructive, .link, .secondary, .pressed): return .textMainButtonDestructiveLinkSecondaryHover
    case (.destructive, .link, .secondary, .disabled): return .textMainButtonDestructiveLinkSecondaryDisabled
    case (.destructive, .description, .primary, .enabled): return .textMainButtonDestructiveDescriptionPrimaryEnabled
    case (.destructive, .description, .primary, .pressed): return .textMainButtonDestructiveDescriptionPrimaryHover
    case (.destructive, .description, .primary, .disabled): return .textMainButtonDestructiveDescriptionPrimaryDisabled
    case (.destructive, .description, .secondary, .enabled): return .textMainButtonDestructiveDescriptionSecondaryEnabled
    case (.destructive, .description, .secondary, .pressed): return .textMainButtonDestructiveDescriptionSecondaryHover
    case (.destructive, .description, .secondary, .disabled): return .textMainButtonDestructiveDescriptionSecondaryDisabled
    default: return nil
    }
}

/// `{Icon}/MainButton/{Color}/{Type}/{Hierarchy}/{State}`
private func mainIconToken(_ color: ButtonColorEnum, _ style: ButtonStyleEnum, _ hierarchy: ButtonHierarchyEnum, _ state: ButtonInteractionState) -> AmityColorToken? {
    switch (color, style, hierarchy, state) {
    case (.default, .filled, .primary, .enabled): return .iconMainButtonDefaultFilledPrimaryEnabled
    case (.default, .filled, .primary, .pressed): return .iconMainButtonDefaultFilledPrimaryHover
    case (.default, .filled, .primary, .disabled): return .iconMainButtonDefaultFilledPrimaryDisabled
    case (.default, .filled, .secondary, .enabled): return .iconMainButtonDefaultFilledSecondaryEnabled
    case (.default, .filled, .secondary, .pressed): return .iconMainButtonDefaultFilledSecondaryHover
    case (.default, .filled, .secondary, .disabled): return .iconMainButtonDefaultFilledSecondaryDisabled
    case (.default, .outlined, .primary, .enabled): return .iconMainButtonDefaultOutlinedPrimaryEnabled
    case (.default, .outlined, .primary, .pressed): return .iconMainButtonDefaultOutlinedPrimaryHover
    case (.default, .outlined, .primary, .disabled): return .iconMainButtonDefaultOutlinedPrimaryDisabled
    case (.default, .outlined, .secondary, .enabled): return .iconMainButtonDefaultOutlinedSecondaryEnabled
    case (.default, .outlined, .secondary, .pressed): return .iconMainButtonDefaultOutlinedSecondaryHover
    case (.default, .outlined, .secondary, .disabled): return .iconMainButtonDefaultOutlinedSecondaryDisabled
    case (.default, .ghost, .primary, .enabled): return .iconMainButtonDefaultGhostPrimaryEnabled
    case (.default, .ghost, .primary, .pressed): return .iconMainButtonDefaultGhostPrimaryHover
    case (.default, .ghost, .primary, .disabled): return .iconMainButtonDefaultGhostPrimaryDisabled
    case (.default, .ghost, .secondary, .enabled): return .iconMainButtonDefaultGhostSecondaryEnabled
    case (.default, .ghost, .secondary, .pressed): return .iconMainButtonDefaultGhostSecondaryHover
    case (.default, .ghost, .secondary, .disabled): return .iconMainButtonDefaultGhostSecondaryDisabled
    case (.default, .inverse, .primary, .enabled): return .iconMainButtonDefaultInversePrimaryEnabled
    case (.default, .inverse, .primary, .pressed): return .iconMainButtonDefaultInversePrimaryHover
    case (.default, .inverse, .primary, .disabled): return .iconMainButtonDefaultInversePrimaryDisabled
    case (.default, .inverse, .secondary, .enabled): return .iconMainButtonDefaultInverseSecondaryEnabled
    case (.default, .inverse, .secondary, .pressed): return .iconMainButtonDefaultInverseSecondaryHover
    case (.default, .inverse, .secondary, .disabled): return .iconMainButtonDefaultInverseSecondaryDisabled
    case (.default, .link, .primary, .enabled): return .iconMainButtonDefaultLinkPrimaryEnabled
    case (.default, .link, .primary, .pressed): return .iconMainButtonDefaultLinkPrimaryHover
    case (.default, .link, .primary, .disabled): return .iconMainButtonDefaultLinkPrimaryDisabled
    case (.default, .link, .secondary, .enabled): return .iconMainButtonDefaultLinkSecondaryEnabled
    case (.default, .link, .secondary, .pressed): return .iconMainButtonDefaultLinkSecondaryHover
    case (.default, .link, .secondary, .disabled): return .iconMainButtonDefaultLinkSecondaryDisabled
    case (.default, .description, .primary, .enabled): return .iconMainButtonDefaultDescriptionPrimaryEnabled
    case (.default, .description, .primary, .pressed): return .iconMainButtonDefaultDescriptionPrimaryHover
    case (.default, .description, .primary, .disabled): return .iconMainButtonDefaultDescriptionPrimaryDisabled
    case (.default, .description, .secondary, .enabled): return .iconMainButtonDefaultDescriptionSecondaryEnabled
    case (.default, .description, .secondary, .pressed): return .iconMainButtonDefaultDescriptionSecondaryHover
    case (.default, .description, .secondary, .disabled): return .iconMainButtonDefaultDescriptionSecondaryDisabled
    case (.default, .transparent, .primary, .enabled): return .iconMainButtonDefaultTransparentPrimaryEnabled
    case (.default, .transparent, .primary, .pressed): return .iconMainButtonDefaultTransparentPrimaryHover
    case (.default, .transparent, .primary, .disabled): return .iconMainButtonDefaultTransparentPrimaryDisabled
    case (.destructive, .filled, .primary, .enabled): return .iconMainButtonDestructiveFilledPrimaryEnabled
    case (.destructive, .filled, .primary, .pressed): return .iconMainButtonDestructiveFilledPrimaryHover
    case (.destructive, .filled, .primary, .disabled): return .iconMainButtonDestructiveFilledPrimaryDisabled
    case (.destructive, .filled, .secondary, .enabled): return .iconMainButtonDestructiveFilledSecondaryEnabled
    case (.destructive, .filled, .secondary, .pressed): return .iconMainButtonDestructiveFilledSecondaryHover
    case (.destructive, .filled, .secondary, .disabled): return .iconMainButtonDestructiveFilledSecondaryDisabled
    case (.destructive, .outlined, .primary, .enabled): return .iconMainButtonDestructiveOutlinedPrimaryEnabled
    case (.destructive, .outlined, .primary, .pressed): return .iconMainButtonDestructiveOutlinedPrimaryHover
    case (.destructive, .outlined, .primary, .disabled): return .iconMainButtonDestructiveOutlinedPrimaryDisabled
    case (.destructive, .outlined, .secondary, .enabled): return .iconMainButtonDestructiveOutlinedSecondaryEnabled
    case (.destructive, .outlined, .secondary, .pressed): return .iconMainButtonDestructiveOutlinedSecondaryHover
    case (.destructive, .outlined, .secondary, .disabled): return .iconMainButtonDestructiveOutlinedSecondaryDisabled
    case (.destructive, .ghost, .primary, .enabled): return .iconMainButtonDestructiveGhostPrimaryEnabled
    case (.destructive, .ghost, .primary, .pressed): return .iconMainButtonDestructiveGhostPrimaryHover
    case (.destructive, .ghost, .primary, .disabled): return .iconMainButtonDestructiveGhostPrimaryDisabled
    case (.destructive, .ghost, .secondary, .enabled): return .iconMainButtonDestructiveGhostSecondaryEnabled
    case (.destructive, .ghost, .secondary, .pressed): return .iconMainButtonDestructiveGhostSecondaryHover
    case (.destructive, .ghost, .secondary, .disabled): return .iconMainButtonDestructiveGhostSecondaryDisabled
    case (.destructive, .inverse, .primary, .enabled): return .iconMainButtonDestructiveInversePrimaryEnabled
    case (.destructive, .inverse, .primary, .pressed): return .iconMainButtonDestructiveInversePrimaryHover
    case (.destructive, .inverse, .primary, .disabled): return .iconMainButtonDestructiveInversePrimaryDisabled
    case (.destructive, .inverse, .secondary, .enabled): return .iconMainButtonDestructiveInverseSecondaryEnabled
    case (.destructive, .inverse, .secondary, .pressed): return .iconMainButtonDestructiveInverseSecondaryHover
    case (.destructive, .inverse, .secondary, .disabled): return .iconMainButtonDestructiveInverseSecondaryDisabled
    case (.destructive, .link, .primary, .enabled): return .iconMainButtonDestructiveLinkPrimaryEnabled
    case (.destructive, .link, .primary, .pressed): return .iconMainButtonDestructiveLinkPrimaryHover
    case (.destructive, .link, .primary, .disabled): return .iconMainButtonDestructiveLinkPrimaryDisabled
    case (.destructive, .link, .secondary, .enabled): return .iconMainButtonDestructiveLinkSecondaryEnabled
    case (.destructive, .link, .secondary, .pressed): return .iconMainButtonDestructiveLinkSecondaryHover
    case (.destructive, .link, .secondary, .disabled): return .iconMainButtonDestructiveLinkSecondaryDisabled
    case (.destructive, .description, .primary, .enabled): return .iconMainButtonDestructiveDescriptionPrimaryEnabled
    case (.destructive, .description, .primary, .pressed): return .iconMainButtonDestructiveDescriptionPrimaryHover
    case (.destructive, .description, .primary, .disabled): return .iconMainButtonDestructiveDescriptionPrimaryDisabled
    case (.destructive, .description, .secondary, .enabled): return .iconMainButtonDestructiveDescriptionSecondaryEnabled
    case (.destructive, .description, .secondary, .pressed): return .iconMainButtonDestructiveDescriptionSecondaryHover
    case (.destructive, .description, .secondary, .disabled): return .iconMainButtonDestructiveDescriptionSecondaryDisabled
    default: return nil
    }
}

/// `{Surface}/IconButton/{Type}/{Hierarchy}/{State}` (State = Enabled/Hover/Disabled)
private func iconSurfaceToken(_ style: ButtonStyleEnum, _ hierarchy: ButtonHierarchyEnum, _ state: ButtonInteractionState) -> AmityColorToken? {
    switch (style, hierarchy, state) {
    case (.filled, .primary, .enabled): return .surfaceIconButtonFilledPrimaryEnabled
    case (.filled, .primary, .pressed): return .surfaceIconButtonFilledPrimaryHover
    case (.filled, .primary, .disabled): return .surfaceIconButtonFilledPrimaryDisabled
    case (.filled, .secondary, .enabled): return .surfaceIconButtonFilledSecondaryEnabled
    case (.filled, .secondary, .pressed): return .surfaceIconButtonFilledSecondaryHover
    case (.filled, .secondary, .disabled): return .surfaceIconButtonFilledSecondaryDisabled
    // Ghost: no iOS surface binding (spec "option A") — IconButton ghost stays transparent in every
    // state; the `/Hover` surface is web-only. Press feedback = glyph Hover tint + native affordance.
    case (.transparent, .primary, .enabled): return .surfaceIconButtonTransparentPrimaryEnabled
    case (.transparent, .primary, .pressed): return .surfaceIconButtonTransparentPrimaryHover
    case (.transparent, .primary, .disabled): return .surfaceIconButtonTransparentPrimaryDisabled
    default: return nil
    }
}

/// `{Icon}/IconButton/{Type}/{Hierarchy}/{State}` (State = Default/Hovered/Disabled)
private func iconGlyphToken(_ style: ButtonStyleEnum, _ hierarchy: ButtonHierarchyEnum, _ state: ButtonInteractionState) -> AmityColorToken? {
    switch (style, hierarchy, state) {
    case (.filled, .primary, .enabled): return .iconIconButtonFilledPrimaryDefault
    case (.filled, .primary, .pressed): return .iconIconButtonFilledPrimaryHovered
    case (.filled, .primary, .disabled): return .iconIconButtonFilledPrimaryDisabled
    case (.filled, .secondary, .enabled): return .iconIconButtonFilledSecondaryDefault
    case (.filled, .secondary, .pressed): return .iconIconButtonFilledSecondaryHovered
    case (.filled, .secondary, .disabled): return .iconIconButtonFilledSecondaryDisabled
    case (.ghost, .primary, .enabled): return .iconIconButtonGhostPrimaryDefault
    case (.ghost, .primary, .pressed): return .iconIconButtonGhostPrimaryHovered
    case (.ghost, .primary, .disabled): return .iconIconButtonGhostPrimaryDisabled
    case (.ghost, .secondary, .enabled): return .iconIconButtonGhostSecondaryDefault
    case (.ghost, .secondary, .pressed): return .iconIconButtonGhostSecondaryHovered
    case (.ghost, .secondary, .disabled): return .iconIconButtonGhostSecondaryDisabled
    case (.transparent, .primary, .enabled): return .iconIconButtonTransparentPrimaryDefault
    case (.transparent, .primary, .pressed): return .iconIconButtonTransparentPrimaryHovered
    case (.transparent, .primary, .disabled): return .iconIconButtonTransparentPrimaryDisabled
    default: return nil
    }
}

/// `{Surface}/SquareButton/{Color}/{Hierarchy}/{State}` — Destructive drops the Hierarchy segment.
private func squareSurfaceToken(_ color: ButtonColorEnum, _ hierarchy: ButtonHierarchyEnum, _ state: ButtonInteractionState) -> AmityColorToken? {
    switch (color, hierarchy, state) {
    case (.default, .primary, .enabled): return .surfaceSquareButtonDefaultPrimaryDefault
    case (.default, .primary, .pressed): return .surfaceSquareButtonDefaultPrimaryHover
    case (.default, .primary, .disabled): return .surfaceSquareButtonDefaultPrimaryDisabled
    case (.default, .secondary, .enabled): return .surfaceSquareButtonDefaultSecondaryDefault
    case (.default, .secondary, .pressed): return .surfaceSquareButtonDefaultSecondaryHover
    case (.default, .secondary, .disabled): return .surfaceSquareButtonDefaultSecondaryDisabled
    case (.destructive, _, .enabled): return .surfaceSquareButtonDestructiveDefault
    case (.destructive, _, .pressed): return .surfaceSquareButtonDestructiveHover
    case (.destructive, _, .disabled): return .surfaceSquareButtonDestructiveDisabled
    default: return nil
    }
}

/// `{Icon}/SquareButton/{Color}/{Hierarchy}/{State}`
private func squareIconToken(_ color: ButtonColorEnum, _ hierarchy: ButtonHierarchyEnum, _ state: ButtonInteractionState) -> AmityColorToken? {
    switch (color, hierarchy, state) {
    case (.default, .primary, .enabled): return .iconSquareButtonDefaultPrimaryDefault
    case (.default, .primary, .pressed): return .iconSquareButtonDefaultPrimaryHover
    case (.default, .primary, .disabled): return .iconSquareButtonDefaultPrimaryDisabled
    case (.default, .secondary, .enabled): return .iconSquareButtonDefaultSecondaryDefault
    case (.default, .secondary, .pressed): return .iconSquareButtonDefaultSecondaryHover
    case (.default, .secondary, .disabled): return .iconSquareButtonDefaultSecondaryDisabled
    case (.destructive, _, .enabled): return .iconSquareButtonDestructiveDefault
    case (.destructive, _, .pressed): return .iconSquareButtonDestructiveHover
    case (.destructive, _, .disabled): return .iconSquareButtonDestructiveDisabled
    default: return nil
    }
}

/// `{Text}/SquareButton/{Color}/{Hierarchy}/{State}`
private func squareTextToken(_ color: ButtonColorEnum, _ hierarchy: ButtonHierarchyEnum, _ state: ButtonInteractionState) -> AmityColorToken? {
    switch (color, hierarchy, state) {
    case (.default, .primary, .enabled): return .textSquareButtonDefaultPrimaryDefault
    case (.default, .primary, .pressed): return .textSquareButtonDefaultPrimaryHover
    case (.default, .primary, .disabled): return .textSquareButtonDefaultPrimaryDisabled
    case (.default, .secondary, .enabled): return .textSquareButtonDefaultSecondaryDefault
    case (.default, .secondary, .pressed): return .textSquareButtonDefaultSecondaryHover
    case (.default, .secondary, .disabled): return .textSquareButtonDefaultSecondaryDisabled
    case (.destructive, _, .enabled): return .textSquareButtonDestructiveDefault
    case (.destructive, _, .pressed): return .textSquareButtonDestructiveHover
    case (.destructive, _, .disabled): return .textSquareButtonDestructiveDisabled
    default: return nil
    }
}
