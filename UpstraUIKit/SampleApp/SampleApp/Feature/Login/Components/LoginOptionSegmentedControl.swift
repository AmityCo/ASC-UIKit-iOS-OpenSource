//
//  LoginOptionSegmentedControl.swift
//  SampleApp
//
//  Segmented picker over every case of an option enum, styled like ThemeSegmentedControl.
//  A new enum case shows up as a new segment with no change here.
//

import SwiftUI

struct LoginOptionSegmentedControl<Option: CaseIterable & Identifiable & Equatable>: View where Option.AllCases: RandomAccessCollection {
    @Binding var selection: Option
    let title: (Option) -> String

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Option.allCases) { option in
                segment(for: option)
            }
        }
    }

    private func segment(for option: Option) -> some View {
        let isSelected = (option == selection)
        let foreground: Color = isSelected ? .white : LoginTheme.primaryText
        let background: Color = isSelected ? LoginTheme.primary : LoginTheme.neutralFill
        let weight: Font.Weight = isSelected ? .bold : .regular

        return Button(action: { selection = option }) {
            Text(title(option))
                .font(.system(size: 14, weight: weight))
                .foregroundColor(foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(background)
                .cornerRadius(8)
        }
        .buttonStyle(.borderless)
    }
}
