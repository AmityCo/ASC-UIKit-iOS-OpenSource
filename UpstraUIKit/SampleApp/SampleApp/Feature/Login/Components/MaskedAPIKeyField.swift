//
//  MaskedAPIKeyField.swift
//  SampleApp
//
//  API-key field value. Renders inside a `LoginInlineField` row (no card of its own).
//  Masked by default with monospaced dots, an eye toggle to reveal, and a ✕ reset.
//

import SwiftUI

struct MaskedAPIKeyField: View {
    @Binding var text: String
    var onReset: () -> Void

    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if isRevealed {
                    TextField("Enter API key…", text: $text)
                } else {
                    SecureField("Enter API key…", text: $text)
                }
            }
            .font(LoginTheme.fieldMonoFont)
            .foregroundColor(LoginTheme.primaryText)
            .autocapitalization(.none)
            .disableAutocorrection(true)

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .font(.system(size: 16))
                    .foregroundColor(LoginTheme.muted)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(isRevealed ? "Hide API key" : "Reveal API key")

            Button {
                onReset()
            } label: {
                ZStack {
                    Circle()
                        .fill(LoginTheme.clearButton)
                        .frame(width: 22, height: 22)
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Reset API key to region default")
        }
    }
}
