//
//  AmitySelection.swift
//  AmityUIKit4
//
//  Design-system ATOM — the atomic RadioAtomic / CheckboxAtomic selection control.
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/Selection/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  Conventions (see AmityToggle, the C1 pattern-setter):
//   • Controlled — the consumer owns the value; the atom never mutates `isSelected`, it only
//     reports the requested change via `onChange`. A radio group's mutual-exclusivity lives in
//     the parent, not here.
//   • Colours resolve through `viewConfig.color(_:)` (page/component-scoped theme).
//   • Interaction/disabled state is resolved internally via a private `ButtonStyle`. Selection
//     tokens have only Default/Disabled (no press/hover/focus token), so press does not alter
//     appearance — the ButtonStyle is used for tap handling + the enabled→disabled token swap.
//   • Additive — this does not touch any existing component (note: the pre-existing
//     `AmitySelectionButtonStyle` in Core/CustomViews is an unrelated legacy button style).
//

import SwiftUI

/// Which control to render. Both share the same 24×24 frame / 20×20 circle geometry and differ
/// only by centre glyph (dot vs. check) and by how the consuming page groups them.
enum SelectionVariantEnum {
    /// RadioAtomic — centre-dot glyph, single-select group semantics.
    case radio
    /// CheckboxAtomic — check-mark glyph, independent multi-select.
    case checkbox
}

/// Atomic selection control — a single RadioAtomic or CheckboxAtomic, controlled by the consumer.
///
///     AmitySelection(variant: .radio, isSelected: mode == .silent, value: "silent",
///                    viewConfig: viewConfig) { selected, value in
///         if selected { mode = .silent }
///     }
struct AmitySelection: View {

    private let variant: SelectionVariantEnum
    private let isSelected: Bool
    private let isDisabled: Bool
    private let value: String?
    private let onChange: (Bool, String?) -> Void
    private let viewConfig: AmityViewConfigController

    init(variant: SelectionVariantEnum,
         isSelected: Bool,
         isDisabled: Bool = false,
         value: String? = nil,
         viewConfig: AmityViewConfigController,
         onChange: @escaping (Bool, String?) -> Void) {
        self.variant = variant
        self.isSelected = isSelected
        self.isDisabled = isDisabled
        self.value = value
        self.viewConfig = viewConfig
        self.onChange = onChange
    }

    var body: some View {
        Button(action: { onChange(!isSelected, value) }) {
            EmptyView()
        }
        .buttonStyle(AmitySelectionAtomStyle(variant: variant, isSelected: isSelected, viewConfig: viewConfig))
        .disabled(isDisabled)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// Renders the selection control (Surface disc + Inactive-only Border ring + centre glyph). Kept as
/// a `ButtonStyle` so tap handling comes from the framework (same idiom as `AmityToggle`);
/// `@Environment(\.isEnabled)` carries the disabled state set by `.disabled(_:)`.
private struct AmitySelectionAtomStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    let variant: SelectionVariantEnum
    let isSelected: Bool
    let viewConfig: AmityViewConfigController

    // Geometry (spec): 24×24 hit-area frame, 20×20 circle (2 pt inset), fully circular (r=100%).
    private let frameSize: CGFloat = 24
    private let circleSize: CGFloat = 20
    private let borderWidth: CGFloat = 1
    private let radioDotSize: CGFloat = 8     // 8×8 centre dot
    private let checkGlyphSize: CGFloat = 14  // ~14×14 check mark

    func makeBody(configuration: Configuration) -> some View {
        // Selection has no press token, so `configuration.isPressed` intentionally drives no colour.
        return ZStack {
            Circle()
                .fill(Color(viewConfig.color(surfaceToken)))
                .overlay(
                    Group {
                        // Border ring is drawn only on the Inactive control (Active is a filled disc).
                        if let borderToken {
                            Circle().strokeBorder(Color(viewConfig.color(borderToken)), lineWidth: borderWidth)
                        }
                    }
                )
                .frame(width: circleSize, height: circleSize)

            // Glyph layer exists in both states; painted at opacity 0 when Inactive (per spec).
            glyph
                .opacity(isSelected ? 1 : 0)
        }
        .frame(width: frameSize, height: frameSize)
        .contentShape(Circle())
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    @ViewBuilder
    private var glyph: some View {
        switch variant {
        case .radio:
            // No bare-dot design-system glyph exists — draw the 8×8 dot as a filled Circle,
            // tinted by the shared Icon/Selection/RadioAtomic token.
            Circle()
                .fill(Color(viewConfig.color(iconToken)))
                .frame(width: radioDotSize, height: radioDotSize)
        case .checkbox:
            Image(AmityIcon.DesignSystem.check1S.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: checkGlyphSize, height: checkGlyphSize)
                .foregroundColor(Color(viewConfig.color(iconToken)))
        }
    }

    // MARK: - Token resolution

    /// Surface binds all four `{Active,Inactive} × {Default,Disabled}` combinations.
    private var surfaceToken: AmityColorToken {
        switch (variant, isSelected, isEnabled) {
        case (.radio, true, true):      return .surfaceSelectionRadioAtomicActiveDefault
        case (.radio, true, false):     return .surfaceSelectionRadioAtomicActiveDisabled
        case (.radio, false, true):     return .surfaceSelectionRadioAtomicInactiveDefault
        case (.radio, false, false):    return .surfaceSelectionRadioAtomicInactiveDisabled
        case (.checkbox, true, true):   return .surfaceSelectionCheckboxAtomicActiveDefault
        case (.checkbox, true, false):  return .surfaceSelectionCheckboxAtomicActiveDisabled
        case (.checkbox, false, true):  return .surfaceSelectionCheckboxAtomicInactiveDefault
        case (.checkbox, false, false): return .surfaceSelectionCheckboxAtomicInactiveDisabled
        }
    }

    /// Border ring exists only for the Inactive control — nil when Active (filled disc, no ring token).
    private var borderToken: AmityColorToken? {
        guard !isSelected else { return nil }
        switch (variant, isEnabled) {
        case (.radio, true):     return .borderSelectionRadioAtomicInactiveDefault
        case (.radio, false):    return .borderSelectionRadioAtomicInactiveDisabled
        case (.checkbox, true):  return .borderSelectionCheckboxAtomicInactiveDefault
        case (.checkbox, false): return .borderSelectionCheckboxAtomicInactiveDisabled
        }
    }

    /// Icon tint has no Active/Inactive split — one token per control, by enabled state only.
    private var iconToken: AmityColorToken {
        switch (variant, isEnabled) {
        case (.radio, true):     return .iconSelectionRadioAtomicDefault
        case (.radio, false):    return .iconSelectionRadioAtomicDisabled
        case (.checkbox, true):  return .iconSelectionCheckboxAtomicDefault
        case (.checkbox, false): return .iconSelectionCheckboxAtomicDisabled
        }
    }
}
