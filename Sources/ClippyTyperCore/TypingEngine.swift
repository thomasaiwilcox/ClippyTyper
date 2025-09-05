import Foundation

public final class TypingEngine {
    public struct KeystrokeEvent: Equatable {
        public let character: Character
        public let delay: TimeInterval // delay before sending this character
        public init(character: Character, delay: TimeInterval) {
            self.character = character
            self.delay = delay
        }
    }

    public typealias Sleep = (TimeInterval) -> Void

    private let sender: KeystrokeSender
    private let sleep: Sleep
    private let maxRetries: Int
    private let retryBackoffBase: TimeInterval

    public init(
        sender: KeystrokeSender,
        sleep: @escaping Sleep = { d in if d > 0 { Thread.sleep(forTimeInterval: d) } },
        maxRetries: Int = 3,
        retryBackoffBase: TimeInterval = 0.03
    ) {
        self.sender = sender
        self.sleep = sleep
        self.maxRetries = max(0, maxRetries)
        self.retryBackoffBase = max(0, retryBackoffBase)
    }

    /// Returns the sequence of keystroke events with per-character delays.
    /// First event uses 0 delay to start promptly; subsequent events use interval derived from cps.
    public func plan(text: String, cps: Double) -> [KeystrokeEvent] {
        let chars = TextTokenizer.tokenize(text)
        guard !chars.isEmpty else { return [] }

        let interval = SpeedController.interval(for: cps)
        var events: [KeystrokeEvent] = []
        events.reserveCapacity(chars.count)

        for (idx, ch) in chars.enumerated() {
            let delay = (idx == 0) ? 0 : interval
            events.append(KeystrokeEvent(character: ch, delay: delay))
        }
        return events
    }

    /// Performs typing by sleeping the planned delays and sending characters via the injected sender.
    /// In tests, provide a `sleep` that does nothing to avoid wall-clock delays.
    public func type(text: String, cps: Double) throws {
        for event in plan(text: text, cps: cps) {
            sleep(event.delay)
            var attempt = 0
            while true {
                do {
                    try sender.send(character: event.character)
                    break
                } catch {
                    if attempt >= maxRetries {
                        throw error
                    }
                    let backoff = retryBackoffBase * pow(2.0, Double(attempt))
                    sleep(backoff)
                    attempt += 1
                }
            }
        }
    }
}
