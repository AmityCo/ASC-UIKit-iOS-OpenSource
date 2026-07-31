//
//  AmitySheet.swift
//  AmityUIKit4
//
//  Design-system ATOM — the modal bottom-sheet / action-sheet container.
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/Sheet/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  Composite atom: owns the drag-handle strip + optional embedded Header (title /
//  description / leading & trailing actions); the body is a host-filled @ViewBuilder
//  content slot. No `variant` (no-discriminator atom, like AmityToggle). Additive — the
//  existing bottomSheet modifier / BottomSheetDragIndicator are untouched.
//

import SwiftUI

struct AmitySheet<Content: View>: View {

    private let title: String?
    private let sheetDescription: String?
    private let leadingAction: AnyView?
    private let trailingAction: AnyView?
    private let content: Content
    private let viewConfig: AmityViewConfigController

    /// Header parts are all optional; when `title`/`sheetDescription`/actions are nil the
    /// header row is omitted (every chat consumer runs Header-off — grab pill + content only).
    init(title: String? = nil,
         description: String? = nil,
         leadingAction: AnyView? = nil,
         trailingAction: AnyView? = nil,
         viewConfig: AmityViewConfigController,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.sheetDescription = description
        self.leadingAction = leadingAction
        self.trailingAction = trailingAction
        self.viewConfig = viewConfig
        self.content = content()
    }

    private var hasHeader: Bool {
        title != nil || sheetDescription != nil || leadingAction != nil || trailingAction != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            handleStrip

            if hasHeader {
                header
            }

            content
        }
        .background(Color(viewConfig.color(.surfaceSheetsBackgroundGeneral)))
        .clipShape(TopRoundedCorners(radius: 20))
    }

    // 375×28 strip with a centered 37×4 grab pill (r12), top corners rounded.
    private var handleStrip: some View {
        ZStack {
            Color(viewConfig.color(.surfaceSheetsBackgroundGeneral))
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(viewConfig.color(.surfaceSheetsHandleDefault)))
                .frame(width: 37, height: 4)
        }
        .frame(height: 28)
        .frame(maxWidth: .infinity)
    }

    private var header: some View {
        VStack(spacing: 4) {
            ZStack {
                if let title {
                    Text(title)
                        .applyTextStyle(.titleBold(Color(viewConfig.color(.textSheetsHeaderTitleDefault))))
                }
                HStack {
                    leadingAction
                    Spacer()
                    trailingAction
                }
            }
            if let sheetDescription {
                Text(sheetDescription)
                    .applyTextStyle(.caption(Color(viewConfig.color(.textSheetsHeaderTextDescriptionDefault))))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

/// Rounds only the top-leading/top-trailing corners (a bottom sheet's bottom edge sits at
/// the screen bottom). iOS-14-safe (no UnevenRoundedRectangle).
private struct TopRoundedCorners: Shape {
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        let r = min(radius, min(rect.width, rect.height) / 2)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r,
                 startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r,
                 startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
