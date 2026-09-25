//
//  NetworkLogBodyFormatterTests.swift
//  SampleAppTests
//

import XCTest
import AmitySDK
@testable import SampleApp

/// A long response body rendered as an empty white block: SwiftUI stops laying out a single
/// `Text` well before the 256 kB a body can reach, and reports nothing when it gives up.
/// Display is therefore clipped independently of capture, and these pin that boundary.
final class NetworkLogBodyFormatterTests: XCTestCase {

    private func body(_ text: String, contentType: String? = "application/json") -> AmityCapturedBody {
        let data = Data(text.utf8)
        return AmityCapturedBody(
            data: data,
            decodedLength: Int64(data.count),
            wireLength: Int64(data.count),
            contentEncoding: nil,
            truncated: false,
            contentType: contentType
        )
    }

    // MARK: - Clipping

    func testAShortBodyIsRenderedWhole() {
        let rendering = NetworkLogBodyFormatter.clip("hello", limit: 100)
        XCTAssertEqual(rendering.text, "hello")
        XCTAssertFalse(rendering.isClipped)
        XCTAssertEqual(rendering.totalCharacters, 5)
    }

    func testALongBodyIsClippedToTheLimitAndSaysSo() {
        let rendering = NetworkLogBodyFormatter.clip(String(repeating: "a", count: 5_000), limit: 1_000)
        XCTAssertEqual(rendering.text.count, 1_000)
        XCTAssertTrue(rendering.isClipped)
        XCTAssertEqual(rendering.totalCharacters, 5_000, "the full length must survive, or the notice lies")
    }

    func testABodyExactlyAtTheLimitIsNotClipped() {
        let rendering = NetworkLogBodyFormatter.clip(String(repeating: "a", count: 1_000), limit: 1_000)
        XCTAssertFalse(rendering.isClipped)
    }

    func testClippingNeverSplitsAMultiByteCharacter() {
        // Slicing by byte rather than character would leave a broken scalar at the boundary.
        let rendering = NetworkLogBodyFormatter.clip(String(repeating: "日本語", count: 100), limit: 10)
        XCTAssertEqual(rendering.text.count, 10)
        XCTAssertEqual(rendering.text, "日本語日本語日本語日")
    }

    // MARK: - The real failure case

    func testAQuarterMegabyteBodyProducesRenderableText() {
        // The capture cap is 256 kB; before this fix the whole thing went into one Text and
        // rendered as an empty block.
        let huge = #"{"items":["# + Array(repeating: #""aaaaaaaaaaaaaaaaaaaa""#, count: 12_000).joined(separator: ",") + "]}"
        XCTAssertGreaterThan(huge.count, 250_000, "precondition: this is a realistically large body")

        let rendering = try! XCTUnwrap(NetworkLogBodyFormatter.rendering(for: body(huge), prettyPrinted: false))
        XCTAssertEqual(rendering.text.count, NetworkLogBodyFormatter.renderCharacterLimit)
        XCTAssertTrue(rendering.isClipped)
        XCTAssertFalse(rendering.text.isEmpty, "the block must never come back empty")
    }

    func testCopyingStillYieldsTheCompleteBody() {
        let full = String(repeating: "x", count: 50_000)
        let copied = try! XCTUnwrap(NetworkLogBodyFormatter.fullText(for: body(full), prettyPrinted: false))
        XCTAssertEqual(copied.count, 50_000, "clipping is for display only — copy must be complete")
    }

    // MARK: - Pretty printing

    func testJsonIsPrettyPrintedWithStableKeyOrder() {
        let pretty = NetworkLogBodyFormatter.prettify(#"{"b":2,"a":1}"#)
        XCTAssertTrue(pretty.contains("\n"), "pretty printing should introduce line breaks")
        XCTAssertLessThan(
            pretty.range(of: "\"a\"")!.lowerBound,
            pretty.range(of: "\"b\"")!.lowerBound,
            "keys should be sorted so two captures compare cleanly"
        )
    }

    func testNonJsonIsReturnedUnchangedRatherThanBlanked() {
        let plain = "not json at all"
        XCTAssertEqual(NetworkLogBodyFormatter.prettify(plain), plain)
    }

    func testRawModeSkipsPrettyPrinting() {
        let compact = #"{"a":1}"#
        XCTAssertEqual(NetworkLogBodyFormatter.fullText(for: body(compact), prettyPrinted: false), compact)
    }

    func testBinaryBodiesProduceNoRenderingRatherThanGarbage() {
        let binary = AmityCapturedBody(
            data: Data([0xFF, 0xFE, 0xFD]), decodedLength: 3, wireLength: 3,
            contentEncoding: nil, truncated: false, contentType: "image/jpeg"
        )
        XCTAssertNil(NetworkLogBodyFormatter.rendering(for: binary, prettyPrinted: true))
    }
}
