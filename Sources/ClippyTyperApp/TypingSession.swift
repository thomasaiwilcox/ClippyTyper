import Foundation
import ClippyTyperCore

final class TypingSession {
    private final class State {
        var isPaused = false
        var isCancelled = false
    }

    private let engine: TypingEngine
    private let queue = DispatchQueue(label: "TypingSession.queue")
    private let state: State
    private let sender: KeystrokeSender

    var isPaused: Bool { state.isPaused }
    var isCancelled: Bool { state.isCancelled }

    init(baseSender: KeystrokeSender) {
        let state = State()
        self.state = state

        let cancellableSender = CancellableSender(underlying: baseSender) {
            state.isCancelled
        }
        self.sender = cancellableSender
        // Inject a sleep that respects pause/cancel in small increments
        func controlledSleep(_ d: TimeInterval) {
            if d <= 0 {
                // immediate dispatch, but wait if paused/cancelled
                while true {
                    if state.isCancelled { return }
                    if !state.isPaused { return }
                    Thread.sleep(forTimeInterval: 0.01)
                }
            } else {
                var remaining = d
                while remaining > 0 {
                    if state.isCancelled { return }
                    if state.isPaused {
                        Thread.sleep(forTimeInterval: 0.01)
                        continue
                    }
                    let step = min(0.01, remaining)
                    Thread.sleep(forTimeInterval: step)
                    remaining -= step
                }
            }
        }
        self.engine = TypingEngine(sender: cancellableSender, sleep: controlledSleep)
    }

    func start(text: String, cps: Double, progress: ((Double) -> Void)? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        queue.async { [weak self] in
            guard let self else { return }
            let events = self.engine.plan(text: text, cps: cps)
            let total = max(1, events.count)
            var idx = 0
            do {
                for event in events {
                    if self.state.isCancelled { throw KeystrokeError.sendFailed("Cancelled") }
                    // sleep respecting pause/cancel
                    if event.delay > 0 {
                        var remaining = event.delay
                        while remaining > 0 {
                            if self.state.isCancelled { throw KeystrokeError.sendFailed("Cancelled") }
                            if self.state.isPaused { Thread.sleep(forTimeInterval: 0.01); continue }
                            let step = min(0.01, remaining)
                            Thread.sleep(forTimeInterval: step)
                            remaining -= step
                        }
                    } else {
                        // handle pause even when delay is 0
                        while self.state.isPaused {
                            if self.state.isCancelled { throw KeystrokeError.sendFailed("Cancelled") }
                            Thread.sleep(forTimeInterval: 0.01)
                        }
                    }

                    var attempt = 0
                    let maxRetries = 3
                    let baseBackoff = 0.03
                    while true {
                        do {
                            try self.sender.send(character: event.character)
                            break
                        } catch {
                            if attempt >= maxRetries { throw error }
                            Thread.sleep(forTimeInterval: baseBackoff * pow(2.0, Double(attempt)))
                            attempt += 1
                        }
                    }
                    idx += 1
                    progress?(Double(idx) / Double(total))
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func pause() { state.isPaused = true }
    func resume() { state.isPaused = false }
    func togglePause() { state.isPaused.toggle() }
    func cancel() { state.isCancelled = true }
}

final class CancellableSender: KeystrokeSender {
    private let underlying: KeystrokeSender
    private let shouldCancel: () -> Bool

    init(underlying: KeystrokeSender, shouldCancel: @escaping () -> Bool) {
        self.underlying = underlying
        self.shouldCancel = shouldCancel
    }

    func send(character: Character) throws {
        if shouldCancel() { throw KeystrokeError.sendFailed("Cancelled") }
        try underlying.send(character: character)
    }
}
