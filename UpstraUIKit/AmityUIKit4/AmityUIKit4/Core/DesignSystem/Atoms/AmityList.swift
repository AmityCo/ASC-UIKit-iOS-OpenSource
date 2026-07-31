//
//  AmityList.swift
//  AmityUIKit4
//
//  Design-system ATOM — the list row (`AmityListItem`).
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/List/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  The most-composed atom. Owns the row surface + text-column tokens + leading-icon tint;
//  the leading (icon/featured-icon/avatar/media), optional leading Controller
//  (checkbox/radio), and trailing (up to 2 of icon/toggle/button/badge/reaction/text) are
//  host-filled AnyView slots (per the spec's component-set slot pattern). Additive — the
//  existing hand-rolled rows are untouched; consumers migrate later.
//

import SwiftUI

enum ListColorEnum {
    case `default`
    case destructive
}

/// Row interaction/loading state. Destructive ships no `active` (maps to default).
enum ListStateEnum {
    case `default`
    case hover
    case active
    case disabled
    case skeleton
}

struct AmityListItem: View {

    private let color: ListColorEnum
    private let state: ListStateEnum
    private let overline: String?
    private let title: String
    private let subhead: String?
    private let itemDescription: String?
    private let leadingControl: AnyView?
    private let leading: AnyView?
    private let trailing: AnyView?
    private let bottom: AnyView?
    private let onPress: (() -> Void)?
    private let viewConfig: AmityViewConfigController

    init(title: String,
         color: ListColorEnum = .default,
         state: ListStateEnum = .default,
         overline: String? = nil,
         subhead: String? = nil,
         description: String? = nil,
         leadingControl: AnyView? = nil,
         leading: AnyView? = nil,
         trailing: AnyView? = nil,
         bottom: AnyView? = nil,
         viewConfig: AmityViewConfigController,
         onPress: (() -> Void)? = nil) {
        self.title = title
        self.color = color
        self.state = state
        self.overline = overline
        self.subhead = subhead
        self.itemDescription = description
        self.leadingControl = leadingControl
        self.leading = leading
        self.trailing = trailing
        self.bottom = bottom
        self.viewConfig = viewConfig
        self.onPress = onPress
    }

    // MARK: - Token resolution

    private var surfaceToken: AmityColorToken {
        if state == .skeleton { return .surfaceListSkeletonSkeleton }
        switch (color, state) {
        case (.default, .hover):      return .surfaceListDefaultHover
        case (.default, .active):     return .surfaceListDefaultActive
        case (.default, .disabled):   return .surfaceListDefaultDisabled
        case (.default, _):           return .surfaceListDefaultDefault
        case (.destructive, .hover):    return .surfaceListDestructiveHover
        case (.destructive, .disabled): return .surfaceListDestructiveDisabled
        case (.destructive, _):         return .surfaceListDestructiveDefault   // no Active for destructive
        }
    }

    private var titleToken: AmityColorToken {
        switch (color, state) {
        case (.default, .disabled):     return .textListHeaderDefaultDisabled
        case (.default, .hover):        return .textListHeaderDefaultHover
        case (.default, _):             return .textListHeaderDefaultDefault
        case (.destructive, .disabled): return .textListHeaderDestructiveDisabled
        case (.destructive, .hover):    return .textListHeaderDestructiveHover
        case (.destructive, _):         return .textListHeaderDestructiveDefault
        }
    }

    var body: some View {
        if let onPress {
            Button(action: onPress) { row }.buttonStyle(.plain).disabled(state == .disabled)
        } else {
            row
        }
    }

    private var row: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if let leadingControl { leadingControl }
                if let leading { leading }

                VStack(alignment: .leading, spacing: 2) {
                    if let overline {
                        Text(overline).applyTextStyle(.captionSmall(Color(viewConfig.color(.textListOverlineDefaultDefault))))
                    }
                    Text(title).applyTextStyle(.bodyBold(Color(viewConfig.color(titleToken))))
                    if let subhead {
                        Text(subhead).applyTextStyle(.caption(Color(viewConfig.color(.textListSubheadDefaultDefault))))
                    }
                    if let itemDescription {
                        Text(itemDescription)
                            .applyTextStyle(.caption(Color(viewConfig.color(.textListTextDescriptionDefaultDefault))))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)

                if let trailing { trailing }
            }

            if let bottom { bottom }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(viewConfig.color(surfaceToken)))
        .contentShape(Rectangle())
        .redacted(reason: state == .skeleton ? .placeholder : [])
    }
}
