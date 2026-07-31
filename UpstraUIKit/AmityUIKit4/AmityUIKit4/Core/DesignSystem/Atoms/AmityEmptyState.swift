//
//  AmityEmptyState.swift
//  AmityUIKit4
//
//  Design-system ATOM — the centered no-content / error placeholder.
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/EmptyState/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  Conventions (see AmityToggle / AmityDivider, the C1 pattern-setters):
//   • Presentational display atom — no interaction of its own; the optional CTA slots
//     delegate to composed `AmityButton` instances.
//   • Colours resolve through `viewConfig.color(_:)`; owns exactly 3 tokens
//     (Icon/EmptyState/Icon/Default, Text/EmptyState/Title/Default,
//     Text/EmptyState/Description/Default). The illustration is an un-tokenized asset.
//   • Additive — does not touch the existing `AmityEmptyStateView`.
//

import SwiftUI

/// Which visual slot renders. Figma `Type` axis.
enum EmptyStateVariantEnum {
    case illustration   // 160×160 decorative asset (own colours, light/dark via asset)
    case icon           // 64×64 glyph tinted by Icon/EmptyState/Icon/Default
}

/// One optional CTA — rendered via the `AmityButton` MainButton atom.
struct AmityEmptyStateAction {
    let label: String
    let icon: AmityIcon.DesignSystem?
    let action: () -> Void

    init(label: String, icon: AmityIcon.DesignSystem? = nil, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.action = action
    }
}

struct AmityEmptyState: View {

    private let variant: EmptyStateVariantEnum
    private let image: ImageResource
    private let title: String
    private let description: String?
    private let primaryAction: AmityEmptyStateAction?
    private let secondaryAction: AmityEmptyStateAction?
    private let viewConfig: AmityViewConfigController

    /// - Parameters:
    ///   - image: the illustration asset (`variant == .illustration`, rendered at 160×160 in its
    ///     own colours) or the icon glyph (`variant == .icon`, rendered at 64×64, template-tinted).
    init(variant: EmptyStateVariantEnum,
         image: ImageResource,
         title: String,
         description: String? = nil,
         primaryAction: AmityEmptyStateAction? = nil,
         secondaryAction: AmityEmptyStateAction? = nil,
         viewConfig: AmityViewConfigController) {
        self.variant = variant
        self.image = image
        self.title = title
        self.description = description
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.viewConfig = viewConfig
    }

    var body: some View {
        // Root: vertical stack, gap 4, centered — [visual · content].
        VStack(spacing: 4) {
            visual

            // Content: [Text → Actions], gap 16.
            VStack(spacing: 16) {
                // Text: [Title → Description], flush (gap 0).
                VStack(spacing: 0) {
                    Text(title)
                        .applyTextStyle(.titleBold(Color(viewConfig.color(.textEmptyStateTitleDefault))))
                        .multilineTextAlignment(.center)

                    if let description {
                        Text(description)
                            .applyTextStyle(.caption(Color(viewConfig.color(.textEmptyStateDescriptionDefault))))
                            .multilineTextAlignment(.center)
                    }
                }

                if primaryAction != nil || secondaryAction != nil {
                    // Actions: stacked vertically, gap 16, each hugs its label.
                    VStack(spacing: 16) {
                        if let primaryAction {
                            AmityButton(variant: .main,
                                        hierarchy: .primary,
                                        style: .filled,
                                        mainSize: .lg,
                                        label: primaryAction.label,
                                        icon: primaryAction.icon,
                                        viewConfig: viewConfig) {
                                primaryAction.action()
                            }
                        }
                        if let secondaryAction {
                            AmityButton(variant: .main,
                                        hierarchy: .primary,
                                        style: .ghost,
                                        mainSize: .lg,
                                        label: secondaryAction.label,
                                        icon: secondaryAction.icon,
                                        viewConfig: viewConfig) {
                                secondaryAction.action()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var visual: some View {
        switch variant {
        case .illustration:
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
        case .icon:
            Image(image)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.color(.iconEmptyStateIconDefault)))
                .frame(width: 64, height: 64)
        }
    }
}
