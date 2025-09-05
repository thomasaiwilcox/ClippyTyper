import Foundation
import ApplicationServices
import Carbon

enum KeyEventUtil {
    static func sendCommandV() {
        guard let src = CGEventSource(stateID: .hidSystemState) else { return }
        let flags: CGEventFlags = [.maskCommand]
        let vCode: CGKeyCode = CGKeyCode(kVK_ANSI_V)
        if let down = CGEvent(keyboardEventSource: src, virtualKey: vCode, keyDown: true) {
            down.flags = flags
            down.post(tap: .cghidEventTap)
        }
        if let up = CGEvent(keyboardEventSource: src, virtualKey: vCode, keyDown: false) {
            up.flags = flags
            up.post(tap: .cghidEventTap)
        }
    }
}

