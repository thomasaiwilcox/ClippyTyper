import XCTest
import ClippyTyperAppSupport

final class HotkeyManagerParseTests: XCTestCase {
    func testParsesSimpleCombo() {
        let p = HotkeyManager.parse(hotkeyString: "ctrl+opt+t")
        XCTAssertNotNil(p)
    }

    func testParsesFunctionKey() {
        let p = HotkeyManager.parse(hotkeyString: "cmd+shift+f12")
        XCTAssertNotNil(p)
    }

    func testParsesPunctuation() {
        let p = HotkeyManager.parse(hotkeyString: "cmd+\\")
        XCTAssertNotNil(p)
    }

    func testRejectsInvalid() {
        XCTAssertNil(HotkeyManager.parse(hotkeyString: ""))
        XCTAssertNil(HotkeyManager.parse(hotkeyString: "unknown+key"))
    }
}

