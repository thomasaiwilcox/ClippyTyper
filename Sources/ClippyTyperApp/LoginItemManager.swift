import Foundation

#if canImport(ServiceManagement)
import ServiceManagement
#endif

enum LoginItemManagerError: Error, CustomStringConvertible {
    case unsupported
    case helperIdentifierMissing
    case smAppService(String)

    var description: String {
        switch self {
        case .unsupported: return "Login item not supported in this environment"
        case .helperIdentifierMissing: return "Helper identifier missing"
        case .smAppService(let msg): return msg
        }
    }
}

enum LoginItemManager {
    // Update if you change the helper target bundle id in Xcode
    static let helperBundleIdentifier = "com.clippytyper.helper"

    private static var isBundledApp: Bool {
        // Simple check: running from an .app bundle
        Bundle.main.bundlePath.hasSuffix(".app")
    }

    static func isEnabled() -> Bool {
        #if canImport(ServiceManagement)
        if #available(macOS 13.0, *) {
            if isBundledApp {
                let service = SMAppService.loginItem(identifier: helperBundleIdentifier)
                switch service.status {
                case .enabled: return true
                default: break
                }
            }
        }
        #endif
        return LaunchAtLoginManager.isEnabled()
    }

    static func setEnabled(_ enabled: Bool) throws {
        #if canImport(ServiceManagement)
        if #available(macOS 13.0, *) {
            if isBundledApp {
                let service = SMAppService.loginItem(identifier: helperBundleIdentifier)
                do {
                    if enabled { try service.register() } else { try service.unregister() }
                    return
                } catch {
                    throw LoginItemManagerError.smAppService(String(describing: error))
                }
            }
        }
        #endif
        // Fallback to LaunchAgent approach in dev/SwiftPM
        try LaunchAtLoginManager.setEnabled(enabled)
    }
}

