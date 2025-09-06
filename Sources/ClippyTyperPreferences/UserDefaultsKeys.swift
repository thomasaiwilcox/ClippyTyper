import Foundation

/// Centralized keys for UserDefaults. Keep in sync with PRD features.
public enum PreferencesKeys {
    public static let typingSpeed = "typingSpeed"           // Double (characters per second)
    public static let hotkey = "hotkey"                     // String (e.g., "ctrl+opt+t"); app-defined format
    public static let launchAtLogin = "launchAtLogin"       // Bool
    public static let emergencyCancelEnabled = "emergencyCancelEnabled" // Bool
    public static let emergencyCancelDoublePressWindow = "emergencyCancelDoublePressWindow" // Double (seconds)
    public static let instantPasteFallback = "instantPasteFallback" // Bool
    public static let perAppExceptions = "perAppExceptions"         // [String] (bundle identifiers)
}

