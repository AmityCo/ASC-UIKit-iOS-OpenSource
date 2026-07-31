//
//  AmityToast.swift
//  AmityUIKit4
//
//  Design-system ATOM — transient status/feedback pill (Surface + optional leading Icon + Text).
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/Toast/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  ⚠️ ADDITIVE — this is a NEW atom, SEPARATE from the legacy `Toast` / `ToastView` /
//     `ToastStyle` / `Toast.showToast` (Core/CustomViews/Toast.swift), which is shared
//     with ~35 Social files and is left completely untouched. Only new consumers
//     (Chat v2) adopt `AmityToast`.
//
//  Follows the conventions set by AmityToggle (the C1 pattern-setter):
//   • Presentational — renders from its inputs. Dismissal *timing* is the presenter's
//     job: this atom exposes `duration`/`onDismiss` for the API surface but does NOT
//     run an auto-dismiss timer itself (the atom is the visual).
//   • Colours resolve through `viewConfig.color(_:)` (page/component-scoped theme).
//   • Leading glyph comes from `AmityIcon.DesignSystem`, template-rendered, tinted by
//     `Icon/CustomToast/Default`. `variant = .loading` substitutes a spinner (the
//     sibling `AmityLoader`, bound to `Surface/Loaders/Spinner/*`), per the spec's
//     Icon-slot substitution rule.
//

import SwiftUI

/// Status semantics that select which leading element renders. Per spec, `variant`
/// selects icon *content* only — there is a single mode-invariant `Default` state for
/// Surface/Text/Icon, so no per-variant recolor happens.
enum ToastVariantEnum {
    case success      // icon slot resolves a success glyph
    case error        // icon slot resolves an error/alert glyph
    case informative  // default — icon slot resolves an info glyph
    case loading      // icon slot is replaced by a spinner
}

/// Atomic transient status/feedback pill — Surface, optional leading Icon, and Text.
/// Has no in-anatomy close affordance; dismissal is time-based or programmatic.
///
///     AmityToast(message: "Message sent", variant: .success,
///                viewConfig: viewConfig) { presenter.hide() }
struct AmityToast: View {

    private let message: String
    private let variant: ToastVariantEnum
    private let showIcon: Bool
    private let duration: Double?
    private let onDismiss: () -> Void
    private let viewConfig: AmityViewConfigController

    init(message: String,
         variant: ToastVariantEnum,
         showIcon: Bool = true,
         duration: Double? = 4000, // ms — API surface only; the presenter owns the timer.
         viewConfig: AmityViewConfigController,
         onDismiss: @escaping () -> Void) {
        self.message = message
        self.variant = variant
        self.showIcon = showIcon
        self.duration = duration
        self.viewConfig = viewConfig
        self.onDismiss = onDismiss
    }

    // Geometry (spec: pill r=8, padding 16·16·16·12 T·R·B·L, gap 12, max 2 lines).
    // ⚠ Unconfirmed by extraction — see the spec's Geometry note.
    private let cornerRadius: CGFloat = 8
    private let iconFrame: CGFloat = 24
    private let glyphSize: CGFloat = 16
    private let gap: CGFloat = 12

    var body: some View {
        HStack(alignment: .center, spacing: gap) {
            if showIcon {
                leadingElement
                    .frame(width: iconFrame, height: iconFrame)
            }

            Text(message)
                .applyTextStyle(.body(Color(viewConfig.color(.textCustomToastDefault))))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(EdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 16))
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(viewConfig.color(.surfaceCustomToastDefaultDefault)))
        )
    }

    @ViewBuilder private var leadingElement: some View {
        switch variant {
        case .loading:
            // Spinner substitute (spec Icon-slot rule) — the sm spinner is 24×24 and fills
            // the leading icon frame; binds Surface/Loaders/Spinner/{Background,Loader}.
            AmityLoader(variant: .spinner, size: .sm, viewConfig: viewConfig)
        case .success, .error, .informative:
            Image(glyph.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: glyphSize, height: glyphSize)
                .foregroundColor(Color(viewConfig.color(.iconCustomToastDefault)))
        }
    }

    /// Leading glyph per variant (drawn from the design-system icon set).
    private var glyph: AmityIcon.DesignSystem {
        switch variant {
        case .success:     return .checkCircleR
        case .error:       return .exclamationCircleR
        case .informative: return .infoCircleR
        case .loading:     return .infoCircleR // unused — spinner rendered instead
        }
    }
}
