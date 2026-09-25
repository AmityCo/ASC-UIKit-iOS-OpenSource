//
//  NetworkLogBodyView.swift
//  SampleApp
//

import SwiftUI
import AmitySDK

/// Renders one captured body.
///
/// Formatting happens off the main thread and once per toggle, not inside `body`. Pretty-
/// printing a 256 kB payload means parsing and re-serialising it, and doing that during view
/// evaluation ran it on every render pass.
@available(iOS 15.0, *)
struct NetworkLogBodyView: View {

    let capturedBody: AmityCapturedBody
    /// Both sizes when the body was compressed, so the ratio is visible.
    let sizeLabel: String?
    /// Set when capture clipped the body at the wire, which is separate from display clipping.
    let captureTruncationNotice: String?

    @State private var isPrettyPrinted = true
    @State private var rendering: NetworkLogBodyRendering?
    @State private var isPreparing = true
    @State private var didCopy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let sizeLabel {
                keyValue("Size", sizeLabel)
            }

            if isPreparing {
                ProgressView()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            } else if let rendering {
                textBlock(rendering)
                controls(for: rendering)
                if rendering.isClipped {
                    notice("Showing the first \(NetworkLogBodyFormatter.renderCharacterLimit) of \(rendering.totalCharacters) characters — copy to get the rest")
                }
            } else {
                notice("Binary body — \(capturedBody.data.count) bytes captured")
            }

            if let captureTruncationNotice {
                notice(captureTruncationNotice)
            }
        }
        .task(id: isPrettyPrinted) {
            await prepare()
        }
    }

    // MARK: - Preparation

    private func prepare() async {
        isPreparing = true
        let body = capturedBody
        let pretty = isPrettyPrinted
        let result = await Task.detached(priority: .userInitiated) {
            NetworkLogBodyFormatter.rendering(for: body, prettyPrinted: pretty)
        }.value
        rendering = result
        isPreparing = false
    }

    // MARK: - Pieces

    @ViewBuilder
    private func textBlock(_ rendering: NetworkLogBodyRendering) -> some View {
        Group {
            // Selection on a very long run is expensive enough to stall scrolling, and a
            // clipped body is copied with the button rather than by hand anyway.
            if rendering.isClipped {
                bodyText(rendering)
            } else {
                bodyText(rendering).textSelection(.enabled)
            }
        }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(9)
            .background(RoundedRectangle(cornerRadius: 8).fill(NetworkLogTheme.backgroundShade1))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
    }

    private func bodyText(_ rendering: NetworkLogBodyRendering) -> some View {
        Text(rendering.text)
            .font(NetworkLogTheme.bodyBlock)
            .foregroundColor(NetworkLogTheme.base)
    }

    private func controls(for rendering: NetworkLogBodyRendering) -> some View {
        HStack(spacing: 14) {
            Button(isPrettyPrinted ? "Show raw" : "Pretty print") {
                isPrettyPrinted.toggle()
            }
            Button(didCopy ? "Copied" : "Copy body") {
                UIPasteboard.general.string = NetworkLogBodyFormatter.fullText(
                    for: capturedBody,
                    prettyPrinted: isPrettyPrinted
                )
                didCopy = true
                UIAccessibility.post(notification: .announcement, argument: "Copied body")
            }
            .disabled(didCopy)
            Spacer()
        }
        .font(NetworkLogTheme.chipLabel)
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }

    private func keyValue(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(key)
                .font(NetworkLogTheme.detailKeyValue)
                .foregroundColor(NetworkLogTheme.baseShade2)
                .frame(width: 112, alignment: .leading)
            Text(value)
                .font(NetworkLogTheme.detailKeyValue)
                .foregroundColor(NetworkLogTheme.base)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
        .overlay(alignment: .bottom) {
            Rectangle().fill(NetworkLogTheme.baseShade4).frame(height: 1)
        }
    }

    private func notice(_ text: String) -> some View {
        Text(text)
            .font(NetworkLogTheme.rowTimestamp)
            .foregroundColor(NetworkLogTheme.warning)
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
