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
            screenViews(in: app, count: 3),
            ["screen home", "screen product  product_id=week_pass", "screen home"])
    }

    @MainActor
    func testSettingsTracksItsOwnScreenViewWithoutHeraldSwiftUI() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Settings"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertEqual(
            screenViews(in: app, count: 3), ["screen home", "screen settings", "screen home"])
    }

    /// The timeline's screen views, newest first, once it has `count` of them. Other lines, such as
    /// the offers' impressions on a product, are left out.
    @MainActor
    private func screenViews(in app: XCUIApplication, count: Int) -> [String] {
        let lines = app.staticTexts.matching(
            NSPredicate(format: "identifier == 'timeline-line' AND label BEGINSWITH 'screen '"))
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
