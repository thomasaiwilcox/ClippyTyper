import Foundation

enum LaunchAtLoginError: Error, CustomStringConvertible {
    case executableNotFound
    case writeFailed(String)
    case launchctlFailed(Int32)

    var description: String {
        switch self {
        case .executableNotFound: return "Executable path not found"
        case .writeFailed(let reason): return "Failed to write LaunchAgent: \(reason)"
        case .launchctlFailed(let code): return "launchctl command failed with code \(code)"
        }
    }
}

final class LaunchAtLoginManager {
    static let label = "com.clippytyper.agent"

    static func isEnabled() -> Bool {
        let fm = FileManager.default
        return fm.fileExists(atPath: agentPlistURL.path)
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try installAgent()
            try bootstrap()
        } else {
            try bootout()
            try uninstallAgent()
        }
    }

    private static func installAgent() throws {
        guard let execPath = Bundle.main.executableURL?.path else { throw LaunchAtLoginError.executableNotFound }
        let fm = FileManager.default
        try fm.createDirectory(at: agentsDirURL, withIntermediateDirectories: true)

        let dict: [String: Any] = [
            "Label": label,
            "RunAtLoad": true,
            "KeepAlive": false,
            "ProgramArguments": [execPath]
        ]

        do {
            let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
            try data.write(to: agentPlistURL, options: .atomic)
        } catch {
            throw LaunchAtLoginError.writeFailed(String(describing: error))
        }
    }

    private static func uninstallAgent() throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: agentPlistURL.path) {
            try fm.removeItem(at: agentPlistURL)
        }
    }

    private static func bootstrap() throws {
        let uid = getuid()
        let code = run("/bin/launchctl", ["bootstrap", "gui/\(uid)", agentPlistURL.path])
        if code != 0 { throw LaunchAtLoginError.launchctlFailed(code) }
    }

    private static func bootout() throws {
        let uid = getuid()
        let code = run("/bin/launchctl", ["bootout", "gui/\(uid)", label])
        if code != 0 { /* still remove file; ignore error for missing job */ }
    }

    private static func run(_ tool: String, _ args: [String]) -> Int32 {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: tool)
        proc.arguments = args
        do {
            try proc.run()
            proc.waitUntilExit()
            return proc.terminationStatus
        } catch {
            return -1
        }
    }

    private static var agentsDirURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents", isDirectory: true)
    }

    private static var agentPlistURL: URL {
        agentsDirURL.appendingPathComponent("\(label).plist")
    }
}

