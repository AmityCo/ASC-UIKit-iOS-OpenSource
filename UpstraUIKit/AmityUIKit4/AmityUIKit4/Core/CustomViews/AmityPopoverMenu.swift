//
//  AmityPopoverMenu.swift
//  AmityUIKit4
//
//  A custom anchored dropdown popover menu, styled from the `Surface/Popover/*`
//  design tokens. Its top-right corner anchors to the bottom-right of the button
//  that opened it, and it dismisses when tapping outside. Generic over a
//  caller-supplied `Hashable` id so a view can host several anchored menus
//  (e.g. distinct nav-bar buttons) and present whichever one is active.
//
//  Usage:
//      @State private var activeMenu: MyMenu?
//      // on each trigger button:
//      button.popoverAnchor(MyMenu.create)
//      // once on the hosting view:
//      .popoverMenu(active: $activeMenu, viewConfig: viewConfig, items: [
//          .create: [AmityPopoverMenuItem(icon: ..., title: ...) { ... }]
//      ])
//

import SwiftUI

/// A single row in an `AmityPopoverMenu`.
struct AmityPopoverMenuItem: Identifiable {
    let id = UUID()
    let icon: ImageResource
    let title: String
    let action: () -> Void

    init(icon: ImageResource, title: String, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.action = action
    }
}

/// Publishes the bounds of each trigger button, keyed by its id, so the menu
/// overlay can anchor to whichever one is active.
struct AmityPopoverAnchorKey<ID: Hashable>: PreferenceKey {
    static var defaultValue: [ID: Anchor<CGRect>] { [:] }
    static func reduce(
        value: inout [ID: Anchor<CGRect>],
        nextValue: () -> [ID: Anchor<CGRect>]
    ) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Tags a trigger button so its frame can anchor the matching popover menu.
    func popoverAnchor<ID: Hashable>(_ id: ID) -> some View {
        anchorPreference(key: AmityPopoverAnchorKey<ID>.self, value: .bounds) { [id: $0] }
    }

    /// Presents the active popover menu, anchored to its trigger button and
    /// dismissable by tapping outside.
    func popoverMenu<ID: Hashable>(
        active: Binding<ID?>,
        viewConfig: AmityViewConfigController,
        width: CGFloat = 240,
        items: [ID: [AmityPopoverMenuItem]]
    ) -> some View {
        overlayPreferenceValue(AmityPopoverAnchorKey<ID>.self) { anchors in
            GeometryReader { proxy in
                if let id = active.wrappedValue,
                   let anchor = anchors[id],
                   let menuItems = items[id] {
                    AmityPopoverMenuOverlay(
                        anchorRect: proxy[anchor],
                        items: menuItems,
                        viewConfig: viewConfig,
                        width: width,
                        onDismiss: { withAnimation(.easeOut(duration: 0.15)) { active.wrappedValue = nil } }
                    )
                }
            }
        }
    }
}

private struct AmityPopoverMenuOverlay: View {
    let anchorRect: CGRect
    let items: [AmityPopoverMenuItem]
    let viewConfig: AmityViewConfigController
    let width: CGFloat
    let onDismiss: () -> Void

    private let gap: CGFloat = 6

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Tap-outside scrim (near-transparent so it stays invisible but hit-testable).
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }

            card
                .frame(width: width, alignment: .leading)
                .background(Color(viewConfig.color(.surfacePopoverBackgroundDefault)))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                // Elevations/Main/Elevation-04
                .shadow(color: Color(red: 0x60 / 255, green: 0x61 / 255, blue: 0x70 / 255).opacity(0.2),
                        radius: 8, x: 0, y: 4)
                .shadow(color: Color(red: 0x28 / 255, green: 0x29 / 255, blue: 0x3D / 255).opacity(0.1),
                        radius: 2, x: 0, y: 0)
                .offset(
                    x: max(8, anchorRect.maxX - width),
                    y: anchorRect.maxY + gap
                )
                .transition(.scale(scale: 0.9, anchor: .topTrailing).combined(with: .opacity))
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                    onDismiss()
                    item.action()
                } label: {
                    HStack(spacing: 8) {
                        Image(item.icon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color(viewConfig.color(.iconListLeadingDefaultDefault)))
                        Text(item.title)
                            .applyTextStyle(.body(Color(viewConfig.color(.textListHeaderDefaultDefault))))
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(AmityPopoverMenuRowStyle(viewConfig: viewConfig))
            }
        }
        .padding(.vertical, 8)
    }
}

/// Row background feedback: pressed rows use the popover-list hover token.
private struct AmityPopoverMenuRowStyle: ButtonStyle {
    let viewConfig: AmityViewConfigController
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? Color(viewConfig.color(.surfacePopoverListsHover))
                    : Color(viewConfig.color(.surfacePopoverListsDefault))
            )
    }
}
