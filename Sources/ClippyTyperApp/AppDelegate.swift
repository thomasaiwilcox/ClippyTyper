import AppKit
import ClippyTyperCore
import ClippyTyperPreferences

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController!
    private var engine: TypingEngine!
    private var sender: KeystrokeSender!
    private var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        PreferencesDefaults.register()

        guard let axSender = AXKeystrokeSender() else {
            NSLog("Failed to create CGEvent source for keystrokes")
            return
        }
        sender = axSender
        engine = TypingEngine(sender: axSender)

        menuBar = MenuBarController()
        menuBar.onStartTyping = { [weak self] in self?.startTypingFromClipboard() }
        menuBar.onOpenPreferences = { Self.openPreferences() }
        menuBar.onQuit = { NSApp.terminate(nil) }

        // Optional: check permissions at launch (non-blocking)
        _ = PermissionsManager.hasAccessibilityPermission() // can prompt later on demand

        // Register global hotkey from preferences
        let hotkeyString = UserDefaults.standard.string(forKey: PreferencesKeys.hotkey) ?? "ctrl+opt+t"
        let hk = HotkeyManager()
        hk.register(hotkeyString: hotkeyString) { [weak self] in
            self?.startTypingFromClipboard()
        }
        self.hotkeyManager = hk
    }

    private func startTypingFromClipboard() {
        guard PermissionsManager.ensureAccessibilityPermission() else {
            PermissionsManager.promptToEnableAccessibility()
            return
        }

        let pasteboard = NSPasteboard.general
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }

        let cps = UserDefaults.standard.double(forKey: PreferencesKeys.typingSpeed)
        let speed = cps > 0 ? cps : 15.0

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try self?.engine.type(text: text, cps: speed)
            } catch {
                NSLog("Typing failed: \(error)")
            }
        }
    }

    private static func openPreferences() {
        NSApp.activate(ignoringOtherApps: true)
        // Placeholder: present Preferences window when implemented
        let alert = NSAlert()
        alert.messageText = "Preferences"
        alert.informativeText = "Preferences UI not yet implemented."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
