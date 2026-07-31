//
//  AmityLoader.swift
//  AmityUIKit4
//
//  Design-system ATOM — loading indicator (Spinner / Upload controller / Upload spinner / Refresher).
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/Loader/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  Follows the conventions set by AmityToggle (the C1 pattern-setter) and the sibling
//  AmityProgress spinner idiom:
//   • Presentational + always-animating — no value/interaction inputs beyond `progress`.
//   • Colours resolve through `viewConfig.color(_:)` (page/component-scoped theme).
//   • Icons (upload cancel ✕, refresher glyph) come from `AmityIcon.DesignSystem`,
//     template-rendered and tinted by an Icon/* token.
//   • Additive — this is a NEW atom. It does NOT touch the Social-shared
//     `ActivityIndicatorView` / `CircularProgressView`.
//
//  ⚠ Refresher binds no colors-v2 `Loaders`-family token (see spec "Naming issues
//    flagged"): its disc fill and update glyph fall back to the closest general tokens
//    (`Surface/Background/Default`, `Icon/General/Default`) — noted at each use site.
//

import SwiftUI

/// Which sub-frame renders.
enum LoaderVariantEnum {
    case spinner        // static donut vector — track ring + coloured arc, rotated in code
    case upload         // Upload controller (determinate) — ring/arc + optional cancel glyph or countdown numeral
    case uploadSpinner  // Upload spinner (indeterminate) — Upload-controller chrome, 90° head spun continuously
    case refresher      // pull-to-refresh disc + update icon
}

/// Intrinsic box variant. `sm`/`lg` apply to `spinner`; `medium`/`large` to `upload`;
/// `uploadSpinner` accepts all four (sm 24 · lg/medium 40 · large 72).
/// Ignored by `refresher` (fixed 40×40 frame).
enum LoaderSizeEnum {
    case sm      // 24×24 — Spinner only
    case lg      // 40×40 — Spinner only
    case medium  // 40×40 — Upload controller only
    case large   // 72×72 — Upload controller only; unlocks the countdown-numeral centre content
}

/// Atomic loading indicator.
///
///     AmityLoader(variant: .spinner, size: .lg, viewConfig: viewConfig)
///
///     AmityLoader(variant: .upload, size: .large, progress: 42,
///                 viewConfig: viewConfig) { uploadTask.cancel() }
struct AmityLoader: View {

    private let variant: LoaderVariantEnum
    private let size: LoaderSizeEnum
    private let progress: Double
    private let onCancel: (() -> Void)?
    private let viewConfig: AmityViewConfigController

    init(variant: LoaderVariantEnum,
         size: LoaderSizeEnum = .lg,
         progress: Double = 0,
         viewConfig: AmityViewConfigController,
         onCancel: (() -> Void)? = nil) {
        self.variant = variant
        self.size = size
        self.progress = progress
        self.viewConfig = viewConfig
        self.onCancel = onCancel
    }

    var body: some View {
        switch variant {
        case .spinner:
            SpinnerLoader(boxSize: spinnerBox, viewConfig: viewConfig)
        case .upload:
            UploadLoader(boxSize: uploadBox,
                         isLarge: size == .large,
                         progress: progress,
                         viewConfig: viewConfig,
                         onCancel: onCancel)
        case .uploadSpinner:
            // Indeterminate counterpart of `.upload`: progress is forced to 0 (a 90° head
            // spun continuously) with no cancel/countdown, reusing the same white
            // UploadController token pair. For media/preview loads where progress is unknown.
            UploadLoader(boxSize: uploadSpinnerBox,
                         isLarge: false,
                         progress: 0,
                         viewConfig: viewConfig,
                         onCancel: nil)
        case .refresher:
            RefresherLoader(viewConfig: viewConfig)
        }
    }

    // Spinner: sm = 24, lg = 40 (any non-`sm` value falls back to the 40 box).
    private var spinnerBox: CGFloat { size == .sm ? 24 : 40 }
    // Upload: medium = 40, large = 72 (any non-`large` value falls back to the 40 box).
    private var uploadBox: CGFloat { size == .large ? 72 : 40 }
    // Upload spinner: sm = 24, large = 72, otherwise (medium/lg) 40 — mirrors the other frames.
    private var uploadSpinnerBox: CGFloat { size == .sm ? 24 : (size == .large ? 72 : 40) }
}

// MARK: - Spinner

/// A rotating donut: faint full-circle track ring + a trimmed coloured arc, spun in code.
/// Same idiom as `AmityProgress`'s spinner (trim 0→0.75, 0.9s linear repeat-forever).
private struct SpinnerLoader: View {

    let boxSize: CGFloat
    let viewConfig: AmityViewConfigController

    @State private var isSpinning = false

    private var lineWidth: CGFloat { boxSize * 0.1 } // 2.4 @ sm, 4 @ lg

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(Color(viewConfig.color(.surfaceLoadersSpinnerIcon)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .background(
                Circle().stroke(Color(viewConfig.color(.surfaceLoadersSpinnerBackground)),
                                lineWidth: lineWidth)
            )
            .frame(width: boxSize, height: boxSize)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(.linear(duration: 0.9).repeatForever(autoreverses: false),
                       value: isSpinning)
            .onAppear { isSpinning = true }
    }
}

// MARK: - Upload controller

/// A 2px background ring + a progress arc. When `progress == 0` the arc is an
/// indeterminate 90° sweep spun in code; otherwise it fills clockwise from the top.
/// Centre content: a cancel ✕ hit-area when `onCancel` is supplied, or a countdown
/// numeral at `large` size (determinate, no cancel).
private struct UploadLoader: View {

    let boxSize: CGFloat
    let isLarge: Bool
    let progress: Double
    let viewConfig: AmityViewConfigController
    let onCancel: (() -> Void)?

    @State private var isSpinning = false

    private var ringWidth: CGFloat { max(boxSize * 0.06, 2) } // spec: 2px centre-stroke ring
    private var clampedProgress: Double { min(max(progress, 0), 100) }
    private var isDeterminate: Bool { clampedProgress > 0 }
    private var cancelGlyph: CGFloat { isLarge ? 16 : 12 }

    var body: some View {
        ZStack {
            // Background ring — token carries the intended (transparent) tone; spec is
            // 80% opacity white (Figma #FFFFFFCC), carried by the token's own alpha (no
            // extra dimming).
            // NOTE: `.surfaceLoadersUploadControllerBackground` correctly resolves to the
            // `backgroundTransparentWhite800` alias, but that alias currently maps to the
            // theme primitive `transparentWhiteShade7Color` = #FFFFFF4D (~30%). Until the
            // transparent-white scale is re-synced (White800 rung → #FFFFFFCC), this ring
            // renders at ~30% rather than the 80% the design specifies. Do NOT hardcode an
            // opacity here — the fix belongs in the token/theme values, not this atom.
            Circle()
                .stroke(Color(viewConfig.color(.surfaceLoadersUploadControllerBackground)),
                        lineWidth: ringWidth)

            arc

            centre
        }
        .padding(ringWidth / 2)
        .frame(width: boxSize, height: boxSize)
        .onAppear { isSpinning = true }
    }

    @ViewBuilder private var arc: some View {
        if isDeterminate {
            // Determinate: fill clockwise from the top edge.
            Circle()
                .trim(from: 0, to: CGFloat(clampedProgress / 100))
                .stroke(Color(viewConfig.color(.surfaceLoadersUploadControllerLoader)),
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .butt))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: clampedProgress)
        } else {
            // Indeterminate: a flat-capped 90° arc spun continuously (spec anatomy).
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(Color(viewConfig.color(.surfaceLoadersUploadControllerLoader)),
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .butt))
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
                .animation(.linear(duration: 0.9).repeatForever(autoreverses: false),
                           value: isSpinning)
        }
    }

    @ViewBuilder private var centre: some View {
        if let onCancel {
            // Loading + Cancel: the one tappable target on the whole atom.
            Button(action: onCancel) {
                Image(AmityIcon.DesignSystem.crossS.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: cancelGlyph, height: cancelGlyph)
                    .frame(width: 24, height: 24) // enlarged hit-area over the ring centre
                    .contentShape(Rectangle())
                    .foregroundColor(Color(viewConfig.color(.iconLoadersUploadControllerDefault)))
            }
            .buttonStyle(.plain)
        } else if isLarge && isDeterminate {
            // Large · Loading: countdown numeral (remaining %). Spec: SF 700 32/48 digit.
            Text("\(Int((100 - clampedProgress).rounded()))")
                .applyTextStyle(.custom(48, .bold,
                                        Color(viewConfig.color(.textLoadersUploadControllerDefault))))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }
}

// MARK: - Refresher

/// Elevated white disc holding an update glyph (pull-to-refresh). Binds no `Loaders`
/// token (see spec) — disc + glyph use general fallbacks. Glyph spins continuously.
private struct RefresherLoader: View {

    let viewConfig: AmityViewConfigController

    @State private var isSpinning = false

    // Spec: 40×40 frame, ≈26.67px disc, 12px glyph.
    private let boxSize: CGFloat = 40
    private let discSize: CGFloat = 26.67
    private let glyphSize: CGFloat = 12

    var body: some View {
        ZStack {
            // ⚠ Fallback: Refresher disc has no colors-v2 token (old-library white literal).
            Circle()
                .fill(Color(viewConfig.color(.surfaceBackgroundDefault)))
                .frame(width: discSize, height: discSize)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2) // elevation, no token

            // ⚠ Fallback: update glyph binds an Alias (Secondary/800) with no token — using
            //   the general icon token; `arrowRotateRight10R` stands in for the update glyph.
            Image(AmityIcon.DesignSystem.arrowRotateRight10R.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: glyphSize, height: glyphSize)
                .foregroundColor(Color(viewConfig.color(.iconGeneralDefault)))
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
                .animation(.linear(duration: 0.9).repeatForever(autoreverses: false),
                           value: isSpinning)
        }
        .frame(width: boxSize, height: boxSize)
        .onAppear { isSpinning = true }
    }
}
