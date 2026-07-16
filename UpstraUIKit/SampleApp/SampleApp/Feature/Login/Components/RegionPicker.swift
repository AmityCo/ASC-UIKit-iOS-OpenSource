//
//  RegionPicker.swift
//  SampleApp
//
//  API-region picker value. Renders inside a `LoginInlineField` row (no card of its
//  own). Uses a SwiftUI `Menu` so tapping shows the dropdown overlay.
//

import SwiftUI

struct RegionPicker: View {
    @Binding var selection: ApiRegion
    var onChange: (ApiRegion) -> Void

    var body: some View {
        Menu {
            ForEach(ApiRegion.allCases) { region in
                Button(action: { select(region) }) {
                    HStack {
                        Text(region.title)
                        if region == selection {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(selection.title)
                    .font(LoginTheme.fieldValueFont)
                    .foregroundColor(LoginTheme.primaryText)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(LoginTheme.muted)
            }
            .contentShape(Rectangle())
        }
    }

    private func select(_ region: ApiRegion) {
        guard region != selection else { return }
        selection = region
        onChange(region)
    }
}
