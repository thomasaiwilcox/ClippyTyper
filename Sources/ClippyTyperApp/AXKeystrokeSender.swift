import Foundation
import ApplicationServices
import ClippyTyperCore

final class AXKeystrokeSender: KeystrokeSender {
    private let source: CGEventSource

    init?() {
        guard let src = CGEventSource(stateID: .hidSystemState) else { return nil }
        src.localEventsSuppressionInterval = 0
        self.source = src
    }

    func send(character: Character) throws {
        guard PermissionsManager.hasAccessibilityPermission() else {
            throw KeystrokeError.sendFailed("Accessibility permission not granted")
        }

        let string = String(character)
        let units = Array(string.utf16)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
            throw KeystrokeError.sendFailed("Unable to create CGEvent")
        }

        units.withUnsafeBufferPointer { buf in
            if let base = buf.baseAddress {
                keyDown.keyboardSetUnicodeString(stringLength: buf.count, unicodeString: base)
                keyUp.keyboardSetUnicodeString(stringLength: buf.count, unicodeString: base)
            }
        }

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
