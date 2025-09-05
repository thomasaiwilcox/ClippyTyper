import XCTest
@testable import ClippyTyperCore

final class TypingEngineTests: XCTestCase {
    private final class FakeSender: KeystrokeSender {
        var sent: [Character] = []
        var failuresRemaining: Int = 0
        func send(character: Character) throws {
            if failuresRemaining > 0 {
                failuresRemaining -= 1
                throw KeystrokeError.sendFailed("injected failure")
            }
            sent.append(character)
        }
    }

    private func approxEqual(_ a: TimeInterval, _ b: TimeInterval, tol: TimeInterval = 1e-6, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertLessThanOrEqual(abs(a - b), tol, file: file, line: line)
    }

    func testPlanSimpleABC() {
        let engine = TypingEngine(sender: FakeSender())
        let events = engine.plan(text: "ABC", cps: 10)
        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events.map { $0.character }, ["A", "B", "C"]) // Characters compare by literal
        approxEqual(events[0].delay, 0)
        approxEqual(events[1].delay, 0.1)
        approxEqual(events[2].delay, 0.1)
    }

    func testPlanMultiline() {
        let engine = TypingEngine(sender: FakeSender())
        let events = engine.plan(text: "A\nB", cps: 5)
        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events.map { $0.character }, ["A", "\n", "B"]) 
        approxEqual(events[0].delay, 0)
        approxEqual(events[1].delay, 0.2)
        approxEqual(events[2].delay, 0.2)
    }

    func testPlanEmojiGraphemeCluster() {
        // Woman technologist emoji is a single extended grapheme cluster
        let text = "👩‍💻" 
        XCTAssertEqual(Array(text).count, 1)
        let engine = TypingEngine(sender: FakeSender())
        let events = engine.plan(text: text, cps: 8)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].character, Character(text))
        approxEqual(events[0].delay, 0)
    }

    func testTypeSendsInOrderWithoutSleepingWhenInjected() throws {
        let sender = FakeSender()
        let engine = TypingEngine(sender: sender, sleep: { _ in })
        try engine.type(text: "Hi", cps: 2)
        XCTAssertEqual(sender.sent, ["H", "i"]) 
    }

    func testEmptyInputProducesNoEvents() throws {
        let sender = FakeSender()
        let engine = TypingEngine(sender: sender, sleep: { _ in })
        XCTAssertEqual(engine.plan(text: "", cps: 10), [])
        try engine.type(text: "", cps: 10)
        XCTAssertTrue(sender.sent.isEmpty)
    }

    func testRetriesOnFailureThenSucceeds() throws {
        let sender = FakeSender()
        sender.failuresRemaining = 2 // first two attempts fail
        let engine = TypingEngine(sender: sender, sleep: { _ in }, maxRetries: 3, retryBackoffBase: 0)
        try engine.type(text: "A", cps: 1)
        XCTAssertEqual(sender.sent, ["A"]) // should succeed after retries
    }
}
