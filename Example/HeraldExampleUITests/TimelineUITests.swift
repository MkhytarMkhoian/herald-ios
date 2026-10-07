import XCTest

/// Runs the app and reads the timeline on the home screen, newest line first.
final class TimelineUITests: XCTestCase {
    @MainActor
    func testScreenViewsReachTheTimelineAsTheUserNavigates() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["week_pass"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertEqual(
            timeline(of: app, lines: 5),
            [
                "screen home", "screen product  product_id=week_pass", "screen home",
                "consent false", "start",
            ])
    }

    @MainActor
    func testSettingsTracksItsOwnScreenViewWithoutHeraldSwiftUI() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Settings"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertEqual(
            timeline(of: app, lines: 5),
            ["screen home", "screen settings", "screen home", "consent false", "start"])
    }

    /// The timeline's lines, newest first, once it has `count` of them.
    @MainActor
    private func timeline(of app: XCUIApplication, lines count: Int) -> [String] {
        let lines = app.staticTexts.matching(identifier: "timeline-line")
        let filled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count == %d", count), object: lines)
        XCTWaiter().wait(for: [filled], timeout: 5)
        var labels: [String] = []
        for index in 0..<lines.count {
            labels.append(lines.element(boundBy: index).label)
        }
        return labels
    }
}
