import AppKit
import ClippyTyperCore
import ClippyTyperPreferences

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController!
    private var baseSender: KeystrokeSender!
    private var hotkeyManager: HotkeyManager?
    private var pauseHotkeyManager: HotkeyManager?
    private var cancelHotkeyManager: HotkeyManager?
    private var prefsWindow: PreferencesWindowController?
    private var session: TypingSession?
    private var keyboardMonitor: KeyboardEventMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        PreferencesDefaults.register()

        guard let axSender = AXKeystrokeSender() else {
            NSLog("Failed to create CGEvent source for keystrokes")
            return
        }
        baseSender = axSender

        menuBar = MenuBarController()
        menuBar.onStartTyping = { [weak self] in self?.startTypingFromClipboard() }
        menuBar.onPauseResume = { [weak self] in self?.togglePause() }
        menuBar.onCancel = { [weak self] in self?.cancelTyping() }
        menuBar.onOpenPreferences = { [weak self] in self?.openPreferences() }
        menuBar.onQuit = { NSApp.terminate(nil) }

        // Optional: check permissions at launch (non-blocking)
        _ = PermissionsManager.hasAccessibilityPermission() // can prompt later on demand

        // Register global hotkey from preferences
        let hotkeyString = UserDefaults.standard.string(forKey: PreferencesKeys.hotkey) ?? "ctrl+opt+t"
        let hk = HotkeyManager()
        hk.register(hotkeyString: hotkeyString) { [weak self] in self?.startTypingFromClipboard() }
        self.hotkeyManager = hk

        let pauseHK = HotkeyManager()
        pauseHK.register(hotkeyString: "ctrl+opt+esc") { [weak self] in self?.togglePause() }
        self.pauseHotkeyManager = pauseHK

        let cancelHK = HotkeyManager()
        cancelHK.register(hotkeyString: "ctrl+opt+cmd+esc") { [weak self] in self?.cancelTyping() }
        self.cancelHotkeyManager = cancelHK

        // Optional emergency monitor: double-press ESC or ctrl+opt+cmd+esc (configurable)
        let window = UserDefaults.standard.double(forKey: PreferencesKeys.emergencyCancelDoublePressWindow)
        let monitor = KeyboardEventMonitor(doubleTapWindow: window > 0 ? window : 0.4)
        monitor.onCancel = { [weak self] in self?.cancelTyping() }
        self.keyboardMonitor = monitor
        if UserDefaults.standard.bool(forKey: PreferencesKeys.emergencyCancelEnabled) {
            monitor.start()
        }
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

        // Cancel any existing session
        session?.cancel()

        let newSession = TypingSession(baseSender: baseSender)
        self.session = newSession
        menuBar.setPaused(false)
        newSession.start(text: text, cps: speed) { result in
            if case .failure(let error) = result { NSLog("Typing failed: \(error)") }
        }
    }

    private func openPreferences() {
        if prefsWindow == nil {
            let vc = PreferencesViewController()
            vc.onTypingSpeedChanged = { _ in /* speed is read on next run; engine uses cps when invoked */ }
            vc.onHotkeyChanged = { [weak self] hotkey in self?.registerHotkey(hotkey) }
            vc.onEmergencyCancelEnabledChanged = { [weak self] enabled in
                guard let self else { return }
                if enabled {
                    if self.keyboardMonitor == nil {
                        let window = UserDefaults.standard.double(forKey: PreferencesKeys.emergencyCancelDoublePressWindow)
                        let m = KeyboardEventMonitor(doubleTapWindow: window > 0 ? window : 0.4)
                        m.onCancel = { [weak self] in self?.cancelTyping() }
                        self.keyboardMonitor = m
                    }
                    self.keyboardMonitor?.start()
                } else {
                    self.keyboardMonitor?.stop()
                }
            }
            vc.onDoublePressWindowChanged = { [weak self] seconds in
                self?.keyboardMonitor?.setDoubleTapWindow(seconds)
            }
            vc.onLaunchAtLoginChanged = { enabled in
                // TODO: Integrate ServiceManagement login item; for now just persist.
                NSLog("Launch at login preference set to: \(enabled)")
            }
            prefsWindow = PreferencesWindowController(contentViewController: vc)
        }
        NSApp.activate(ignoringOtherApps: true)
        prefsWindow?.showWindow(nil)
        prefsWindow?.window?.makeKeyAndOrderFront(nil)
    }

    private func registerHotkey(_ hotkeyString: String) {
        if hotkeyManager == nil { hotkeyManager = HotkeyManager() }
        hotkeyManager?.register(hotkeyString: hotkeyString) { [weak self] in
            self?.startTypingFromClipboard()
        }
    }

    private func togglePause() {
        guard let session else { return }
        session.togglePause()
        menuBar.setPaused(session.isPaused)
    }

    private func cancelTyping() {
        session?.cancel()
        menuBar.setPaused(false)
    }
}
