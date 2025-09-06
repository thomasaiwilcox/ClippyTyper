import Foundation

/// Registers sensible defaults at app launch.
public enum PreferencesDefaults {
    public static let values: [String: Any] = [
        PreferencesKeys.typingSpeed: 15.0,
        PreferencesKeys.hotkey: "ctrl+opt+t",
        PreferencesKeys.launchAtLogin: false,
        PreferencesKeys.emergencyCancelEnabled: true,
        PreferencesKeys.emergencyCancelDoublePressWindow: 0.4,
        PreferencesKeys.instantPasteFallback: false,
        PreferencesKeys.perAppExceptions: []
    ]

    public static func register() {
        UserDefaults.standard.register(defaults: values)
    }
}

