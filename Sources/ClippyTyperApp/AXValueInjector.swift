import Foundation
import ApplicationServices

enum AXValueInjector {
    /// Attempts to set the focused text field/area value directly via Accessibility.
    /// Returns true if the value was set, false otherwise.
    static func trySetValue(_ text: String) -> Bool {
        let sys = AXUIElementCreateSystemWide()
        var focusedObj: CFTypeRef?
        let getFocused = AXUIElementCopyAttributeValue(sys, kAXFocusedUIElementAttribute as CFString, &focusedObj)
        guard getFocused == .success, let focused = focusedObj else { return false }
        let element = focused as! AXUIElement

        // Check that the value attribute is settable
        var isSettable: DarwinBoolean = false
        let settable = AXUIElementIsAttributeSettable(element, kAXValueAttribute as CFString, &isSettable)
        guard settable == .success, isSettable.boolValue else { return false }

        let cfText = text as CFString
        let set = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, cfText)
        return set == .success
    }
}

