import Foundation
import ApplicationServices

enum PermissionsManager {
    static func hasAccessibilityPermission() -> Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    static func ensureAccessibilityPermission() -> Bool {
        if AXIsProcessTrusted() { return true }
        // Non-blocking check; do not auto-prompt to avoid surprise dialogs
        return false
    }

    static func promptToEnableAccessibility() {
        let options: CFDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
