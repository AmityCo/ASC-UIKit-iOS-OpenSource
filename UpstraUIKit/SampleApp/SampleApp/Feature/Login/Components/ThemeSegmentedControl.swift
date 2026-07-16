//
//  ThemeSegmentedControl.swift
//  SampleApp
//
//  Three-segment Theme picker (Default / Light / Dark). Selected segment uses the
//  primary accent; unselected segments use the neutral fill.
//

import SwiftUI

struct ThemeSegmentedControl: View {
    @Binding var selection: ThemeOption

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ThemeOption.allCases) { option in
                segment(for: option)
            }
        }
    }

    private func segment(for option: ThemeOption) -> some View {
        let isSelected = (option == selection)
        let foreground: Color = isSelected ? .white : LoginTheme.primaryText
        let background: Color = isSelected ? LoginTheme.primary : LoginTheme.neutralFill
        let weight: Font.Weight = isSelected ? .bold : .regular

        return Button(action: { selection = option }) {
            Text(option.title)
                .font(.system(size: 14, weight: weight))
                .foregroundColor(foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(background)
                .cornerRadius(8)
        }
        .buttonStyle(.borderless)
    }
}
