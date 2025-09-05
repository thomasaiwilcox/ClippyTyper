import XCTest

final class ClippyTyperUITests: XCTestCase {
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        // App is background-only (menu bar). Assert it didn’t crash.
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground)
    }
}

