//
//  AmityNetworkLogFilterStrip.swift
//  SampleApp
//

import SwiftUI

/// Horizontally scrollable, never wrapping. Each chip carries its count in a monospace suffix.
/// - Note: Gated to iOS 15. The sample app targets iOS 14 to match the SDK, but this is a
///   debug-only surface and testers run current iOS, so it uses modern SwiftUI rather
///   than constraining the whole viewer to iOS 14 idioms.
@available(iOS 15.0, *)
struct AmityNetworkLogFilterStrip: View {

    @ObservedObject var model: AmityNetworkLogViewModel
    let counts: [AmityNetworkLogFilter: Int]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                chip(title: "All", count: counts.values.reduce(0, +), isSelected: model.selectedFilters.isEmpty) {
                    model.selectedFilters.removeAll()
                }
                ForEach(AmityNetworkLogFilter.allCases, id: \.self) { filter in
                    chip(
                        title: filter.title,
                        count: counts[filter] ?? 0,
                        isSelected: model.selectedFilters.contains(filter)
                    ) {
                        model.toggle(filter)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
    }

    private func chip(title: String, count: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title).font(NetworkLogTheme.chipLabel)
                Text("\(count)").font(NetworkLogTheme.panelCount)
            }
            // `background` is the token that inverts correctly against a `base` fill in both
            // themes; a base-inverse equivalent is black in light mode and vanishes here.
            .foregroundColor(isSelected ? NetworkLogTheme.background : NetworkLogTheme.baseShade1)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 11)
                    .fill(isSelected ? NetworkLogTheme.base : NetworkLogTheme.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .strokeBorder(isSelected ? .clear : NetworkLogTheme.baseShade4, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(count) entries")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
