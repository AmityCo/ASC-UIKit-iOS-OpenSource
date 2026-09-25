//
//  NetworkLogBodyFormatter.swift
//  SampleApp
//

import Foundation
import AmitySDK

/// What the detail view should draw for one captured body.
struct NetworkLogBodyRendering: Equatable {
    /// The text to put on screen — never more than the render limit.
    let text: String
    /// Characters in the full body, before clipping for display.
    let totalCharacters: Int
    /// `true` when `text` is a prefix rather than the whole body.
    let isClipped: Bool
}

/// Turns a captured body into something a `Text` can actually draw.
///
/// Bodies are captured up to 256 kB, which is far more than SwiftUI will lay out in a single
/// `Text`: past roughly ten thousand characters it stops rendering and leaves an empty block,
/// with no error. So display is clipped separately from capture, and the view says so rather
/// than appearing to show a complete body.
enum NetworkLogBodyFormatter {

    /// Comfortably under where `Text` starts failing, and still far more than anyone reads on
    /// a phone before reaching for copy.
    static let renderCharacterLimit = 8_000

    /// The complete body as text, pretty-printed when asked and parseable. Used for copying,
    /// where there is no layout limit.
    static func fullText(for body: AmityCapturedBody, prettyPrinted: Bool) -> String? {
        guard let raw = String(data: body.data, encoding: .utf8) else { return nil }
        return prettyPrinted ? prettify(raw) : raw
    }

    /// The body clipped to something renderable.
    static func rendering(
        for body: AmityCapturedBody,
        prettyPrinted: Bool,
        limit: Int = renderCharacterLimit
    ) -> NetworkLogBodyRendering? {
        guard let full = fullText(for: body, prettyPrinted: prettyPrinted) else { return nil }
        return clip(full, limit: limit)
    }

    static func clip(_ text: String, limit: Int = renderCharacterLimit) -> NetworkLogBodyRendering {
        let total = text.count
        guard total > limit else {
            return NetworkLogBodyRendering(text: text, totalCharacters: total, isClipped: false)
        }
        // Prefix by character, never by byte: slicing UTF-8 mid-scalar produces mojibake.
        return NetworkLogBodyRendering(
            text: String(text.prefix(limit)),
            totalCharacters: total,
            isClipped: true
        )
    }

    /// Returns the input unchanged when it is not JSON, so non-JSON bodies still display.
    static func prettify(_ text: String) -> String {
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(
                  withJSONObject: object,
                  options: [.prettyPrinted, .sortedKeys]
              ),
              let string = String(data: pretty, encoding: .utf8)
        else { return text }
        return string
    }
}
