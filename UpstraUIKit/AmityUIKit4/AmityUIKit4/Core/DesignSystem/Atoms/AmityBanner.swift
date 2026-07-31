//
//  AmityBanner.swift
//  AmityUIKit4
//
//  Design-system ATOM — the inline banner row (leading · text column · trailing).
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/Banner/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  This atom owns the container surface + the text-column tokens; leading & trailing are
//  host-filled AnyView slots (per the spec's Leading/Trailing component-set pattern).
//  Hierarchy selects the whole token family: Default → WhiteBG, Subdue → GreyBG.
//  Additive — existing banner views (surfaceBannerSubdueGeneral consumers) untouched.
//

import SwiftUI

/// Figma `Hierachy` (sic) — picks the WhiteBG vs GreyBG token family.
enum BannerHierarchyEnum {
    case `default`   // WhiteBG family
    case subdue      // GreyBG family
}

struct AmityBanner: View {

    private let hierarchy: BannerHierarchyEnum
    private let overline: String?
    private let header: String
    private let subhead: String?
    private let bannerDescription: String?
    private let trailingText: String?
    private let leading: AnyView?
    private let trailing: AnyView?
    private let isSkeleton: Bool
    private let viewConfig: AmityViewConfigController

    init(hierarchy: BannerHierarchyEnum = .default,
         header: String,
         overline: String? = nil,
         subhead: String? = nil,
         description: String? = nil,
         trailingText: String? = nil,
         leading: AnyView? = nil,
         trailing: AnyView? = nil,
         isSkeleton: Bool = false,
         viewConfig: AmityViewConfigController) {
        self.hierarchy = hierarchy
        self.header = header
        self.overline = overline
        self.subhead = subhead
        self.bannerDescription = description
        self.trailingText = trailingText
        self.leading = leading
        self.trailing = trailing
        self.isSkeleton = isSkeleton
        self.viewConfig = viewConfig
    }

    private var isGrey: Bool { hierarchy == .subdue }

    private var surfaceToken: AmityColorToken { isGrey ? .surfaceBannerSubdueGeneral : .surfaceBannerDefaultGeneral }
    private var overlineToken: AmityColorToken { isGrey ? .textBannerSubdueOverlineGeneral : .textBannerDefaultOverlineGeneral }
    private var headerToken: AmityColorToken { isGrey ? .textBannerSubdueHeaderGeneral : .textBannerDefaultHeaderGeneral }
    private var subheadToken: AmityColorToken { isGrey ? .textBannerSubdueSubheadGeneral : .textBannerDefaultSubheadGeneral }
    private var descriptionToken: AmityColorToken { isGrey ? .textBannerSubdueTextDescriptionGeneral : .textBannerDefaultTextDescriptionGeneral }
    private var trailingTextToken: AmityColorToken { isGrey ? .textBannerSubdueTrailingTextGeneral : .textBannerDefaultTrailingTextGeneral }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let leading { leading }

            VStack(alignment: .leading, spacing: 2) {
                if let overline {
                    Text(overline).applyTextStyle(.captionSmall(Color(viewConfig.color(overlineToken))))
                }
                Text(header).applyTextStyle(.bodyBold(Color(viewConfig.color(headerToken))))
                if let subhead {
                    Text(subhead).applyTextStyle(.caption(Color(viewConfig.color(subheadToken))))
                }
                if let bannerDescription {
                    Text(bannerDescription)
                        .applyTextStyle(.caption(Color(viewConfig.color(descriptionToken))))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            if let trailingText {
                Text(trailingText).applyTextStyle(.caption(Color(viewConfig.color(trailingTextToken))))
            }
            if let trailing { trailing }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(viewConfig.color(surfaceToken)))
        .redacted(reason: isSkeleton ? .placeholder : [])
    }
}
