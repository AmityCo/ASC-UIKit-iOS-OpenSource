//
//  AmityToggle.swift
//  AmityUIKit4
//
//  Design-system ATOM — on/off switch.
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/Toggle/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  Conventions established by this first atom (C1 pattern-setter):
//   • Presentational + controlled — the consumer owns the value; the atom never
//     mutates `isOn`, it only reports the requested change via `onChange`.
//   • Colours resolve through `viewConfig.color(_:)` (page/component-scoped theme).
//   • Icons come from `AmityIcon.DesignSystem` (template-rendered, tinted by an Icon/* token).
//   • Interaction state (pressed/disabled) is resolved internally; only value + disabled
//     are inputs. iOS has no hover/focus, so those token states are unused here.
//   • Additive — this does not touch any existing component.
//

import SwiftUI

/// On/off switch atom. Track (`Background`) + sliding Thumb, with an optional glyph inside the thumb.
///
///     AmityToggle(isOn: viewModel.isEnabled, viewConfig: viewConfig) { newValue in
///         viewModel.isEnabled = newValue
///     }
struct AmityToggle: View {

    private let isOn: Bool
    private let isDisabled: Bool
    private let icon: AmityIcon.DesignSystem?
    private let onChange: (Bool) -> Void
    private let viewConfig: AmityViewConfigController

    init(isOn: Bool,
         isDisabled: Bool = false,
         icon: AmityIcon.DesignSystem? = nil,
         viewConfig: AmityViewConfigController,
         onChange: @escaping (Bool) -> Void) {
        self.isOn = isOn
        self.isDisabled = isDisabled
        self.icon = icon
        self.viewConfig = viewConfig
        self.onChange = onChange
    }

    var body: some View {
        Button(action: { onChange(!isOn) }) {
            EmptyView()
        }
        .buttonStyle(AmityToggleButtonStyle(isOn: isOn, icon: icon, viewConfig: viewConfig))
        .disabled(isDisabled)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}

/// Renders the toggle track + thumb. Kept as a `ButtonStyle` so press state and tap handling come
/// from the framework (same idiom as `AmityButtonStyle`); `@Environment(\.isEnabled)` carries the
/// disabled state set by `.disabled(_:)`.
private struct AmityToggleButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    let isOn: Bool
    let icon: AmityIcon.DesignSystem?
    let viewConfig: AmityViewConfigController

    // iOS geometry (spec: track 48×28, r=H/2 pill). Thumb inset 2 → 24pt, travels ±10 from centre.
    private let trackWidth: CGFloat = 48
    private let trackHeight: CGFloat = 28
    private let thumbInset: CGFloat = 2
    private var thumbSize: CGFloat { trackHeight - thumbInset * 2 }
    private var thumbOffset: CGFloat { (trackWidth - thumbSize) / 2 - thumbInset }
    private let iconSize: CGFloat = 16

    private enum InteractionState { case enabled, pressed, disabled }

    func makeBody(configuration: Configuration) -> some View {
        let state: InteractionState = !isEnabled ? .disabled : (configuration.isPressed ? .pressed : .enabled)

        return Capsule()
            .fill(Color(viewConfig.color(trackSurfaceToken(state))))
            .overlay(
                Capsule().strokeBorder(Color(viewConfig.color(trackBorderToken(state))), lineWidth: 1)
            )
            .frame(width: trackWidth, height: trackHeight)
            .overlay(thumb(state))
            .animation(.easeInOut(duration: 0.18), value: isOn)
            .contentShape(Capsule())
    }

    private func thumb(_ state: InteractionState) -> some View {
        ZStack {
            Circle()
                .fill(Color(viewConfig.color(thumbSurfaceToken(state))))
                .overlay(
                    Group {
                        if let borderToken = thumbBorderToken(state) {
                            Circle().strokeBorder(Color(viewConfig.color(borderToken)), lineWidth: 1)
                        }
                    }
                )

            if let icon {
                Image(icon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(Color(viewConfig.color(iconToken)))
            }
        }
        .frame(width: thumbSize, height: thumbSize)
        .offset(x: isOn ? thumbOffset : -thumbOffset)
    }

    // MARK: - Token resolution

    private func trackSurfaceToken(_ state: InteractionState) -> AmityColorToken {
        switch (isOn, state) {
        case (true, .enabled):   return .surfaceToggleBackgroundActiveEnabled
        case (true, .pressed):   return .surfaceToggleBackgroundActivePressed
        case (true, .disabled):  return .surfaceToggleBackgroundActiveDisabled
        case (false, .enabled):  return .surfaceToggleBackgroundInactiveEnabled
        case (false, .pressed):  return .surfaceToggleBackgroundInactivePressed
        case (false, .disabled): return .surfaceToggleBackgroundInactiveDisabled
        }
    }

    private func trackBorderToken(_ state: InteractionState) -> AmityColorToken {
        switch (isOn, state) {
        case (true, .enabled):   return .borderToggleBackgroundActiveEnabled
        case (true, .pressed):   return .borderToggleBackgroundActivePressed
        case (true, .disabled):  return .borderToggleBackgroundActiveDisabled
        case (false, .enabled):  return .borderToggleBackgroundInactiveEnabled
        case (false, .pressed):  return .borderToggleBackgroundInactivePressed
        case (false, .disabled): return .borderToggleBackgroundInactiveDisabled
        }
    }

    private func thumbSurfaceToken(_ state: InteractionState) -> AmityColorToken {
        switch (isOn, state) {
        case (true, .enabled):   return .surfaceToggleThumbActiveEnabled
        case (true, .pressed):   return .surfaceToggleThumbActivePressed
        case (true, .disabled):  return .surfaceToggleThumbActiveDisabled
        case (false, .enabled):  return .surfaceToggleThumbInactiveEnabled
        case (false, .pressed):  return .surfaceToggleThumbInactivePressed
        case (false, .disabled): return .surfaceToggleThumbInactiveDisabled
        }
    }

    /// Thumb border only exists for Focused/Hovered/Pressed — no Enabled/Disabled token (borderless).
    private func thumbBorderToken(_ state: InteractionState) -> AmityColorToken? {
        guard state == .pressed else { return nil }
        return isOn ? .borderToggleThumbActivePressed : .borderToggleThumbInactivePressed
    }

    /// Icon tone is fixed by on/off value only (no per-interaction-state token).
    private var iconToken: AmityColorToken {
        isOn ? .iconToggleActiveGeneral : .iconToggleInactiveGeneral
    }
}
