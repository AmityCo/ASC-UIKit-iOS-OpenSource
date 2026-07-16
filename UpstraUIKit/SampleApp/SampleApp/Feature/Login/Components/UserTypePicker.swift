//
//  UserTypePicker.swift
//  SampleApp
//
//  User-type picker value. Renders inside a `LoginInlineField` row.
//

import SwiftUI

struct UserTypePicker: View {
    @Binding var selection: UserType

    var body: some View {
        Menu {
            ForEach(UserType.allCases) { type in
                Button(action: { selection = type }) {
                    HStack {
                        Text(type.title)
                        if type == selection {
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
}
