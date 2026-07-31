//
//  AmityTab.swift
//  AmityUIKit4
//
//  Design-system ATOM — a single selectable tab item (one segment of a tab bar).
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/Tab/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  Conventions (see AmityToggle, the C1 pattern-setter):
//   • Presentational + controlled — which tab is Active is owned by the parent bar and passed in via
//     `selected`; the atom never mutates it, it only reports taps via `onPress`.
//   • Colours resolve through `viewConfig.color(_:)` (page/component-scoped theme). No hardcoded hex.
//   • Icons come from `AmityIcon.DesignSystem` (template-rendered, tinted by an Icon/Tab/* token).
//   • Interaction state (press/disabled) is resolved internally via a private `ButtonStyle`; only
//     `selected` (→ Active), `disabled` (→ Disabled) and `loading` (→ Skeleton, pill only) are inputs.
//     iOS has no hover/focus, so the Tab `*/Hover` token states are intentionally never bound here.
//   • Additive — this does NOT touch the pre-existing, Social-shared `SegmentedPickerView`; it is a
//     new, separate atom modelled on the Tab spec's token grammar.
//

import SwiftUI

/// Which of the three tab types to render. Selects both the parts drawn and the token row family
/// (token grammar `{Part}/Tab/{Pill|Underlined|Icon}/{State}`, per the Tab spec Design Tokens table).
enum TabVariantEnum {
    /// Filled, 1px-bordered, r24 pill — the chat-home / feed tab style. Uses `label`.
    case pill
    /// Text-only label with a 2px bottom indicator line on Active. Uses `label`.
    case underlined
    /// 24px icon glyph with a 2px bottom indicator line on Active. Uses `icon`.
    case icon
}

/// Atomic tab item — one selectable segment in a tab bar. Rendered as `pill`, `underlined`, or `icon`.
/// The Active look (SemiBold label / indicator line) is driven by `selected`; Press/Disabled are
/// resolved internally.
///
///     AmityTab(variant: .pill, label: "For You", selected: tab == .forYou,
///              viewConfig: viewConfig) {
///         tab = .forYou
///     }
struct AmityTab: View {

    private let variant: TabVariantEnum
    private let label: String?
    private let icon: AmityIcon.DesignSystem?
    private let selected: Bool
    private let disabled: Bool
    private let loading: Bool
    private let onPress: () -> Void
    private let viewConfig: AmityViewConfigController

    init(variant: TabVariantEnum,
         label: String? = nil,
         icon: AmityIcon.DesignSystem? = nil,
         selected: Bool = false,
         disabled: Bool = false,
         loading: Bool = false,
         viewConfig: AmityViewConfigController,
         onPress: @escaping () -> Void) {
        self.variant = variant
        self.label = label
        self.icon = icon
        self.selected = selected
        self.disabled = disabled
        self.loading = loading
        self.viewConfig = viewConfig
        self.onPress = onPress
    }

    var body: some View {
        Button(action: {
            // `disabled` taps are already blocked by `.disabled(_:)`. `loading` suppresses the
            // callback for every variant (the Skeleton render itself is pill-only, see the style).
            guard !loading else { return }
            onPress()
        }) {
            EmptyView()
        }
        .buttonStyle(AmityTabButtonStyle(variant: variant,
                                         label: label,
                                         icon: icon,
                                         selected: selected,
                                         loading: loading,
                                         viewConfig: viewConfig))
        .disabled(disabled)
        .accessibilityLabel(label ?? "")
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}

/// Renders the tab item for the selected `variant`. Kept as a `ButtonStyle` so press state and tap
/// handling come from the framework (same idiom as `AmityToggle`); `@Environment(\.isEnabled)`
/// carries the disabled state set by `.disabled(_:)`.
private struct AmityTabButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    let variant: TabVariantEnum
    let label: String?
    let icon: AmityIcon.DesignSystem?
    let selected: Bool
    let loading: Bool
    let viewConfig: AmityViewConfigController

    // Geometry (Tab spec). Pill hugs its content (fixed 40 height, r24, 12 h-padding). Width reserves
    // the SemiBold label size in every state (see pill()), so the Active/Default weight change doesn't
    // resize the pill. Underlined/Icon stack a
    // label/glyph over a 2px bottom indicator with the documented gap.
    private let pillHeight: CGFloat = 40
    private let pillRadius: CGFloat = 24
    private let pillHPadding: CGFloat = 12
    private let pillBorderWidth: CGFloat = 1
    private let skeletonWidth: CGFloat = 68     // no label in Skeleton → fall back to the Default pill width
    private let indicatorHeight: CGFloat = 2
    private let underlinedGap: CGFloat = 14      // gap between label and the indicator slot
    private let underlinedTopPadding: CGFloat = 16   // top-only inset → 16 + label(24) + 14 gap + 2 line = 56h (spec 2026-07-14)
    private let iconGlyphSize: CGFloat = 24
    private let iconTopPadding: CGFloat = 16     // Icon variant has top-only padding (spec geometry)
    private let iconSlot: CGFloat = 16           // icon → indicator slot (holds the 2px line at its base)

    /// State axis of the token grammar. iOS has no hover, so `.hover` is never produced here.
    private enum TabRenderState { case `default`, press, active, disabled, skeleton }

    func makeBody(configuration: Configuration) -> some View {
        let state = resolveState(isPressed: configuration.isPressed)
        return content(state)
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.15), value: selected)
    }

    /// Precedence: Skeleton (pill+loading) → Disabled → Active(selected) → Press → Default.
    /// Active wins over Press so pressing an already-selected tab does not drop its indicator line.
    private func resolveState(isPressed: Bool) -> TabRenderState {
        if variant == .pill && loading { return .skeleton }
        if !isEnabled { return .disabled }
        if selected { return .active }
        if isPressed { return .press }
        return .default
    }

    @ViewBuilder
    private func content(_ state: TabRenderState) -> some View {
        switch variant {
        case .pill:        pill(state)
        case .underlined:  underlined(state)
        case .icon:        iconTab(state)
        }
    }

    // MARK: - Pill

    @ViewBuilder
    private func pill(_ state: TabRenderState) -> some View {
        if state == .skeleton {
            // Skeleton replaces surface + border + label with the shared skeleton fill (no border row).
            RoundedRectangle(cornerRadius: pillRadius)
                .fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
                .frame(width: skeletonWidth, height: pillHeight)
        } else {
            // Hidden SemiBold copy reserves a constant width across states.
            Text(label ?? "")
                .applyTextStyle(.titleBold(.clear))
                .lineLimit(1)
                .overlay(
                    Text(label ?? "")
                        .applyTextStyle(pillLabelStyle(state))
                        .lineLimit(1)
                )
                .padding(.horizontal, pillHPadding)
                .frame(height: pillHeight)
                .background(
                    RoundedRectangle(cornerRadius: pillRadius)
                        .fill(Color(viewConfig.color(pillSurfaceToken(state))))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: pillRadius)
                        .strokeBorder(Color(viewConfig.color(pillBorderToken(state))), lineWidth: pillBorderWidth)
                )
        }
    }

    private func pillLabelStyle(_ state: TabRenderState) -> AmityTextStyle {
        let color = Color(viewConfig.color(pillTextToken(state)))
        // Active label is SemiBold 17/24; all other states Regular 17/24.
        return state == .active ? .titleBold(color) : .title(color)
    }

    // MARK: - Underlined

    @ViewBuilder
    private func underlined(_ state: TabRenderState) -> some View {
        Text(label ?? "")
            .applyTextStyle(underlinedLabelStyle(state))
            .lineLimit(1)
            .padding(.top, underlinedTopPadding)
            .padding(.bottom, underlinedGap + indicatorHeight)
            .overlay(indicator(active: state == .active, activeToken: .lineTabUnderlinedActive), alignment: .bottom)
    }

    private func underlinedLabelStyle(_ state: TabRenderState) -> AmityTextStyle {
        let color = Color(viewConfig.color(underlinedTextToken(state)))
        return state == .active ? .titleBold(color) : .title(color)
    }

    // MARK: - Icon

    @ViewBuilder
    private func iconTab(_ state: TabRenderState) -> some View {
        Group {
            if let icon {
                Image(icon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconGlyphSize, height: iconGlyphSize)
                    .foregroundColor(Color(viewConfig.color(iconTintToken(state))))
            } else {
                // No glyph supplied — reserve the 24×24 slot so the indicator/geometry stay stable.
                Color.clear.frame(width: iconGlyphSize, height: iconGlyphSize)
            }
        }
        .padding(.top, iconTopPadding)
        .padding(.bottom, iconSlot)
        .overlay(indicator(active: state == .active, activeToken: .lineTabIconActive), alignment: .bottom)
    }

    // MARK: - Shared indicator

    /// The 2px bottom indicator line (Underlined / Icon). Painted only on Active; it spans the width
    /// of the content above it (the overlay inherits the padded label/glyph frame) and is transparent
    /// otherwise so the layout never shifts between states.
    private func indicator(active: Bool, activeToken: AmityColorToken) -> some View {
        Rectangle()
            .fill(active ? Color(viewConfig.color(activeToken)) : Color.clear)
            .frame(height: indicatorHeight)
    }

    // MARK: - Token resolution

    /// `Surface/Tab/Pill/{State}` (Skeleton handled separately via `surfaceSkeletonEffectDefault`).
    private func pillSurfaceToken(_ state: TabRenderState) -> AmityColorToken {
        switch state {
        case .default:  return .surfaceTabPillDefault
        case .press:    return .surfaceTabPillPress
        case .active:   return .surfaceTabPillActive
        case .disabled: return .surfaceTabPillDisabled
        case .skeleton: return .surfaceSkeletonEffectDefault
        }
    }

    /// `Border/Tab/Pill/{State}` — a first-class part present in every pill state (Skeleton draws no pill).
    private func pillBorderToken(_ state: TabRenderState) -> AmityColorToken {
        switch state {
        case .default:  return .borderTabPillDefault
        case .press:    return .borderTabPillPress
        case .active:   return .borderTabPillActive
        case .disabled: return .borderTabPillDisabled
        case .skeleton: return .borderTabPillDefault   // unreachable: Skeleton renders no bordered pill
        }
    }

    /// `Text/Tab/Pill/{State}`.
    private func pillTextToken(_ state: TabRenderState) -> AmityColorToken {
        switch state {
        case .default:  return .textTabPillDefault
        case .press:    return .textTabPillPress
        case .active:   return .textTabPillActive
        case .disabled: return .textTabPillDisabled
        case .skeleton: return .textTabPillDefault     // unreachable: Skeleton renders no label
        }
    }

    /// `Text/Tab/Underlined/{State}`.
    private func underlinedTextToken(_ state: TabRenderState) -> AmityColorToken {
        switch state {
        case .default:  return .textTabUnderlinedDefault
        case .press:    return .textTabUnderlinedPress
        case .active:   return .textTabUnderlinedActive
        case .disabled: return .textTabUnderlinedDisabled
        case .skeleton: return .textTabUnderlinedDefault  // unreachable: no Skeleton row for Underlined
        }
    }

    /// `Icon/Tab/{State}` — NOTE: the icon-tint path has NO Pill/Underlined/Icon sub-segment;
    /// it is `iconTab{State}` directly.
    private func iconTintToken(_ state: TabRenderState) -> AmityColorToken {
        switch state {
        case .default:  return .iconTabDefault
        case .press:    return .iconTabPress
        case .active:   return .iconTabActive
        case .disabled: return .iconTabDisabled
        case .skeleton: return .iconTabDefault         // unreachable: no Skeleton row for Icon
        }
    }
}
