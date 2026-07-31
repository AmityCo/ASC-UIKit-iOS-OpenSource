//
//  AmityProgress.swift
//  AmityUIKit4
//
//  Design-system ATOM — linear progress / video scrubber (and an indeterminate spinner).
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/Progress/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  Follows the conventions set by AmityToggle (the C1 pattern-setter):
//   • Presentational + controlled — the consumer owns `value`; the atom draws the bar
//     from it and reports drag requests via `onSeek`/`onChange` (it never mutates value).
//   • Colours resolve through `viewConfig.color(_:)` (page/component-scoped theme).
//   • Additive — this is a NEW atom. It does NOT touch the Social-shared
//     `CircularProgressView` (which is circular, not this linear scrubber).
//   • No icon.
//

import SwiftUI

/// Which sub-frame to render.
enum ProgressVariantEnum {
    case scrubber  // Video Controller — determinate Bar (Empty/Filled) + draggable Knob
    case spinner   // indeterminate loading/buffering, no Knob
}

/// Bar-segment visual state (scrubber only).
enum ProgressStateEnum {
    case empty     // unplayed remainder — no fill
    case filled    // played portion — binds Bar/Filled
    case loading   // buffering; no distinct token, falls back to Bar/Filled (per spec)
}

/// Atomic linear-progress control.
///
///     AmityProgress(variant: .scrubber,
///                   value: player.percent,
///                   viewConfig: viewConfig,
///                   onSeek: { player.preview($0) },
///                   onChange: { player.seek(to: $0) })
struct AmityProgress: View {

    private let variant: ProgressVariantEnum
    private let value: Double
    private let state: ProgressStateEnum
    private let onSeek: ((Double) -> Void)?
    private let onChange: ((Double) -> Void)?
    private let viewConfig: AmityViewConfigController

    @State private var isSpinning = false

    init(variant: ProgressVariantEnum,
         value: Double = 0,
         state: ProgressStateEnum = .filled,
         viewConfig: AmityViewConfigController,
         onSeek: ((Double) -> Void)? = nil,
         onChange: ((Double) -> Void)? = nil) {
        self.variant = variant
        self.value = value
        self.state = state
        self.viewConfig = viewConfig
        self.onSeek = onSeek
        self.onChange = onChange
    }

    var body: some View {
        switch variant {
        case .scrubber: scrubber
        case .spinner:  spinner
        }
    }

    // MARK: - Scrubber (Video Controller)

    // Geometry (spec: Bar 328×20 r12, Knob 24×24). Width comes from the parent.
    private let barHeight: CGFloat = 20
    private let emptyBarRadius: CGFloat = 2
    private let filledBarRadius: CGFloat = 3
    private let knobSize: CGFloat = 24

    private var clampedValue: Double { min(max(value, 0), 100) }

    /// `.empty` shows no fill; `.filled`/`.loading` fill to `value`%.
    private var fillFraction: CGFloat {
        state == .empty ? 0 : CGFloat(clampedValue / 100)
    }

    private var scrubber: some View {
        GeometryReader { proxy in
            let trackWidth = proxy.size.width
            let filledWidth = trackWidth * fillFraction
            // Keep the knob centre inside the track.
            let knobX = min(max(filledWidth - knobSize / 2, 0), trackWidth - knobSize)

            ZStack(alignment: .leading) {
                // Empty track (unplayed remainder)
                RoundedRectangle(cornerRadius: emptyBarRadius, style: .continuous)
                    .fill(Color(viewConfig.color(.surfaceProgressBarEmpty)))
                    .frame(height: barHeight)

                // Filled portion (played) — `.loading` falls back to the same token.
                RoundedRectangle(cornerRadius: filledBarRadius, style: .continuous)
                    .fill(Color(viewConfig.color(.surfaceProgressBarFilled)))
                    .frame(width: filledWidth, height: barHeight)

                // Draggable knob
                Circle()
                    .fill(Color(viewConfig.color(.surfaceProgressKnobDefault)))
                    .frame(width: knobSize, height: knobSize)
                    .offset(x: knobX)
                    .gesture(dragGesture(trackWidth: trackWidth))
            }
            .frame(width: trackWidth, height: max(barHeight, knobSize), alignment: .leading)
        }
        .frame(height: max(barHeight, knobSize))
    }

    /// Controlled drag: reports the requested position via callbacks; the knob only
    /// moves once the consumer feeds the new `value` back in (same contract as AmityToggle).
    private func dragGesture(trackWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                onSeek?(position(for: g.location.x, trackWidth: trackWidth))
            }
            .onEnded { g in
                onChange?(position(for: g.location.x, trackWidth: trackWidth))
            }
    }

    private func position(for x: CGFloat, trackWidth: CGFloat) -> Double {
        guard trackWidth > 0 else { return 0 }
        return min(max(Double(x / trackWidth) * 100, 0), 100)
    }

    // MARK: - Spinner (indeterminate)

    // The Spinner sub-frame sits outside the Progress token family — per spec it reuses
    // the Loaders family. Kept intentionally minimal (a single rotating arc), not over-built.
    private var spinner: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(Color(viewConfig.color(.surfaceLoadersSpinnerIcon)),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .background(
                Circle().stroke(Color(viewConfig.color(.surfaceLoadersSpinnerBackground)),
                                lineWidth: 3)
            )
            .frame(width: 24, height: 24)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(.linear(duration: 0.9).repeatForever(autoreverses: false),
                       value: isSpinning)
            .onAppear { isSpinning = true }
    }
}
