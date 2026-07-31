//
//  AmityChip.swift
//  AmityUIKit4
//
//  Design-system ATOM — the selectable/removable pill (leading avatar · label · trailing action).
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/Chip/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  Composite atom: this atom owns ONLY the pill (surface / border / label). The leading
//  (Avatar) and trailing (IconButton) are slots filled by the caller with other atoms —
//  exposed as `AnyView?` (same slot pattern as AmityAvatar's indicator). 12 Chips tokens
//  across Surface / Border / Text; no Icon role of its own.
//

import SwiftUI

/// Surface treatment.
enum ChipTypeEnum {
    case filled
    case outlined
}

/// Chip size — M (36 pt tall) or Sm (20 pt tall).
enum ChipSizeEnum {
    case m
    case sm
}

struct AmityChip: View {

    private let type: ChipTypeEnum
    private let size: ChipSizeEnum
    private let label: String
    private let isDisabled: Bool
    private let leading: AnyView?
    private let trailing: AnyView?
    private let viewConfig: AmityViewConfigController

    init(type: ChipTypeEnum,
         size: ChipSizeEnum = .m,
         label: String,
         isDisabled: Bool = false,
         leading: AnyView? = nil,
         trailing: AnyView? = nil,
         viewConfig: AmityViewConfigController) {
        self.type = type
        self.size = size
        self.label = label
        self.isDisabled = isDisabled
        self.leading = leading
        self.trailing = trailing
        self.viewConfig = viewConfig
    }

    // Geometry per size (spec Geometry table).
    private var height: CGFloat { size == .m ? 36 : 20 }
    private var containerPadding: CGFloat { size == .m ? 4 : 2 }
    private var labelInset: CGFloat { size == .m ? 8 : 4 }
    private var labelStyle: AmityTextStyle {
        size == .m
            ? .bodyBold(Color(viewConfig.color(textToken)))   // SF Pro SemiBold 15/20
            : .caption(Color(viewConfig.color(textToken)))    // SF Pro Regular 13/18
    }

    private var surfaceToken: AmityColorToken {
        switch (type, isDisabled) {
        case (.filled, false):   return .surfaceChipsFilledDefault
        case (.filled, true):    return .surfaceChipsFilledDisabled
        case (.outlined, false): return .surfaceChipsOutlinedDefault
        case (.outlined, true):  return .surfaceChipsOutlinedDisabled
        }
    }

    private var textToken: AmityColorToken {
        switch (type, isDisabled) {
        case (.filled, false):   return .textChipsFilledDefault
        case (.filled, true):    return .textChipsFilledDisabled
        case (.outlined, false): return .textChipsOutlinedDefault
        case (.outlined, true):  return .textChipsOutlinedDisabled
        }
    }

    private var borderToken: AmityColorToken {
        switch (type, isDisabled) {
        case (.filled, false):   return .borderChipsFilledEnabled
        case (.filled, true):    return .borderChipsFilledDisabled
        case (.outlined, false): return .borderChipsOutlinedEnabled
        case (.outlined, true):  return .borderChipsOutlinedDisabled
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            if let leading {
                leading
            }

            Text(label)
                .applyTextStyle(labelStyle)
                .padding(.horizontal, labelInset)

            if let trailing {
                trailing
            }
        }
        .padding(containerPadding)
        .frame(height: height)
        .background(Color(viewConfig.color(surfaceToken)))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(viewConfig.color(borderToken)), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
