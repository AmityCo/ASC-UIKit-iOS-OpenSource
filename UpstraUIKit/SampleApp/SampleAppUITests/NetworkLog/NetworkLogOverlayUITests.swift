//
//  NetworkLogOverlayUITests.swift
//  SampleAppUITests
//

import XCTest

/// End-to-end cover for the launcher and the viewer it presents.
///
/// This exists because the first implementation rendered correctly and was completely inert:
/// the overlay window swallowed every touch, so tapping the launcher did nothing at all, with
/// no error anywhere. Unit tests cannot catch that.
final class NetworkLogOverlayUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    private var launcher: XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Network log,"))
            .firstMatch
    }

    func testTheLauncherIsPresentOnLaunch() {
        XCTAssertTrue(launcher.waitForExistence(timeout: 20), "the launcher should attach before login")
    }

    func testTappingTheLauncherPresentsTheViewer() {
        XCTAssertTrue(launcher.waitForExistence(timeout: 20))
        launcher.tap()
        XCTAssertTrue(app.staticTexts["Network Log"].waitForExistence(timeout: 5),
                      "tapping the launcher must present the viewer")
    }

    func testClosingTheViewerReturnsToTheAppAndTheLauncher() {
        XCTAssertTrue(launcher.waitForExistence(timeout: 20))
        launcher.tap()
        XCTAssertTrue(app.staticTexts["Network Log"].waitForExistence(timeout: 5))

        app.buttons["Close"].tap()
        XCTAssertTrue(launcher.waitForExistence(timeout: 5), "the launcher should come back")
        XCTAssertFalse(app.staticTexts["Network Log"].exists, "the viewer should be gone")
    }

    func testTheFilterChipsAreReachableInTheViewer() {
        XCTAssertTrue(launcher.waitForExistence(timeout: 20))
        launcher.tap()
        XCTAssertTrue(app.staticTexts["Network Log"].waitForExistence(timeout: 5))

        // Labelled "<name>, <count> entries" for accessibility.
        let restChip = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "REST,")).firstMatch
        XCTAssertTrue(restChip.waitForExistence(timeout: 5), "filter chips should be reachable")
        restChip.tap()
    }

    func testTheViewerOpensAtTheHalfHeightDetentAndCanBeExpanded() {
        XCTAssertTrue(launcher.waitForExistence(timeout: 20))
        launcher.tap()

        let title = app.staticTexts["Network Log"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))

        // Opens partially covering the app, so the control offers to expand.
        let expand = app.buttons["Expand"]
        XCTAssertTrue(expand.waitForExistence(timeout: 5), "the viewer should open at the smaller detent")

        // The sheet must actually move, not merely relabel its control. Asserting on the
        // label alone passes even when the detent never changes.
        let halfHeightTop = title.frame.minY
        expand.tap()

        let collapse = app.buttons["Collapse"]
        XCTAssertTrue(collapse.waitForExistence(timeout: 5),
                      "expanding should flip the control to collapse")
        let fullHeightTop = title.frame.minY
        XCTAssertLessThan(fullHeightTop, halfHeightTop - 100,
                          "expanding must raise the sheet, not just relabel the button")

        collapse.tap()
        XCTAssertTrue(app.buttons["Expand"].waitForExistence(timeout: 5),
                      "collapsing should flip it back")
        XCTAssertGreaterThan(title.frame.minY, fullHeightTop + 100,
                             "collapsing must lower the sheet again")
    }

    func testDraggingTheSheetKeepsTheExpandControlInStep() {
        // Dragging and tapping are two routes to the same state. If dragging does not update
        // the control, the next tap asks for the detent the sheet is already at and nothing
        // happens — which reads as the button being broken.
        XCTAssertTrue(launcher.waitForExistence(timeout: 20))
        launcher.tap()

        let title = app.staticTexts["Network Log"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Expand"].exists, "precondition: opens at the smaller detent")

        // Drag the sheet up by its header to the full-height detent.
        let start = title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05))
        start.press(forDuration: 0.1, thenDragTo: end)

        XCTAssertTrue(app.buttons["Collapse"].waitForExistence(timeout: 5),
                      "after dragging to full height the control should offer to collapse")

        app.buttons["Collapse"].tap()
        XCTAssertTrue(app.buttons["Expand"].waitForExistence(timeout: 5),
                      "and tapping it should then collapse the sheet")
    }

    func testTheAppBehindStaysInteractiveWhileTheViewerIsOpen() {
        // The reason for the undimmed detent: a tester drives the app and watches the traffic
        // it makes. Without it this is just a modal and the log is a report, not an inspector.
        XCTAssertTrue(launcher.waitForExistence(timeout: 20))
        launcher.tap()
        XCTAssertTrue(app.staticTexts["Network Log"].waitForExistence(timeout: 5))

        let userIdField = app.textFields.firstMatch
        guard userIdField.waitForExistence(timeout: 5), userIdField.isHittable else {
            XCTFail("app content above the sheet should still be reachable")
            return
        }
        userIdField.tap()
        XCTAssertTrue(app.staticTexts["Network Log"].exists,
                      "interacting with the app must not dismiss the viewer")
    }

    func testTheAppRemainsUsableWithTheLauncherOnScreen() {
        // The launcher floats over every page, so it must not block the controls beneath it.
        XCTAssertTrue(launcher.waitForExistence(timeout: 20))
        let advanced = app.buttons["Advanced options…"].firstMatch
        if advanced.waitForExistence(timeout: 5) {
            advanced.tap()
            XCTAssertTrue(app.staticTexts["Advanced"].waitForExistence(timeout: 5),
                          "app content must still receive touches with the launcher on screen")
        }
    }
}
