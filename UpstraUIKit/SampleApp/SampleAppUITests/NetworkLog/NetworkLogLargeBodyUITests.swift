//
//  NetworkLogLargeBodyUITests.swift
//  SampleAppUITests
//

import XCTest

/// Long response bodies broke the detail view twice, in ways nothing else caught.
///
/// First the body rendered as an empty white block: SwiftUI gives up laying out a single very
/// long `Text` and reports nothing. Then scrolling back up past the body jumped, because a
/// `LazyVStack` does not measure offscreen children and re-measured the block on the way back.
///
/// Both need a body far larger than a login happens to produce, so the app seeds one when
/// launched with `-seedNetworkLog`.
final class NetworkLogLargeBodyUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-seedNetworkLog"]
        app.launch()
    }

    private func openLargeBodyDetail() {
        let launcher = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Network log,")).firstMatch
        XCTAssertTrue(launcher.waitForExistence(timeout: 20))
        launcher.tap()
        XCTAssertTrue(app.staticTexts["Network Log"].waitForExistence(timeout: 5))

        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "/api/v4/uitest/large")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "the seeded row should be listed")
        row.tap()
        XCTAssertTrue(app.staticTexts["RESPONSE BODY"].waitForExistence(timeout: 10))
    }

    func testALargeBodyRendersItsTextRatherThanAnEmptyBlock() {
        openLargeBodyDetail()
        // Keys sort when pretty-printed, so "items" is what lands in the visible prefix.
        let bodyText = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "\"items\"")).firstMatch
        XCTAssertTrue(bodyText.waitForExistence(timeout: 10),
                      "a large body must render its text, not an empty block")
    }

    func testALargeBodySaysItIsClippedForDisplay() {
        openLargeBodyDetail()
        let notice = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Showing the first")).firstMatch
        XCTAssertTrue(notice.waitForExistence(timeout: 10),
                      "a clipped body must say so rather than looking complete")
    }

    func testScrollingDownPastTheBodyAndBackUpReturnsToTheTop() {
        openLargeBodyDetail()

        let requestHeader = app.staticTexts["REQUEST"]
        XCTAssertTrue(requestHeader.exists, "precondition: the page starts at the top")

        for _ in 0..<6 { app.swipeUp(velocity: .fast) }
        XCTAssertFalse(requestHeader.isHittable, "precondition: scrolled away from the top")

        for _ in 0..<12 { app.swipeDown(velocity: .fast) }

        XCTAssertTrue(requestHeader.waitForExistence(timeout: 5),
                      "scrolling back up past a long body must reach the top again, not dismiss the sheet")
        XCTAssertTrue(requestHeader.isHittable,
                      "the top of the page must be reachable, not stuck behind the body block")
    }

    func testTheViewerCanBeClosedFromTheDetailView() {
        openLargeBodyDetail()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Network Log"].waitForExistence(timeout: 5),
                      "closing detail should return to the timeline")
    }
}
