import Foundation

extension Notification.Name {
    static let hotkeyRegistrationResult = Notification.Name("HotkeyRegistrationResult")
    static let clippyStart = Notification.Name("ClippyTyper.StartTyping")
    static let clippyPauseToggle = Notification.Name("ClippyTyper.PauseToggle")
    static let clippyCancel = Notification.Name("ClippyTyper.CancelTyping")
}

struct HotkeyRegistrationInfo {
    let success: Bool
    let hotkey: String
    let message: String?
}
