import Foundation

extension Notification.Name {
    static let hotkeyRegistrationResult = Notification.Name("HotkeyRegistrationResult")
}

struct HotkeyRegistrationInfo {
    let success: Bool
    let hotkey: String
    let message: String?
}

