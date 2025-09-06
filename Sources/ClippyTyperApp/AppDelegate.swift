import AppKit
import ClippyTyperCore
import ClippyTyperPreferences
import ClippyTyperAppSupport

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController!
    private var baseSender: KeystrokeSender!
    private var hotkeyManager: HotkeyManager?
    private var pauseHotkeyManager: HotkeyManager?
    private var cancelHotkeyManager: HotkeyManager?
    private var prefsWindow: PreferencesWindowController?
    private var helpWindow: HelpWindowController?
    private var permissionsWindow: PermissionsWindowController?
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
        menuBar.onExcludeCurrentApp = { [weak self] in self?.excludeCurrentApp() }
        menuBar.onOpenPreferences = { [weak self] in self?.openPreferences() }
        menuBar.onOpenHelp = { [weak self] in self?.openHelp() }
        menuBar.onOpenPermissions = { [weak self] in self?.openPermissions() }
        menuBar.onQuit = { NSApp.terminate(nil) }

        // Optional: check permissions at launch (non-blocking)
        _ = PermissionsManager.hasAccessibilityPermission() // can prompt later on demand

        // Distributed control (CLI): start/pause/cancel
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(self, selector: #selector(handleDistributedStart), name: .clippyStart, object: nil)
        dnc.addObserver(self, selector: #selector(handleDistributedPauseToggle), name: .clippyPauseToggle, object: nil)
        dnc.addObserver(self, selector: #selector(handleDistributedCancel), name: .clippyCancel, object: nil)

        // Register global hotkey from preferences
        let hotkeyString = UserDefaults.standard.string(forKey: PreferencesKeys.hotkey) ?? "ctrl+opt+t"
        self.hotkeyManager = HotkeyManager()
        self.registerHotkey(hotkeyString)

        let pauseHK = HotkeyManager()
        pauseHK.register(hotkeyString: "ctrl+opt+esc") { [weak self] in self?.togglePause() }
        self.pauseHotkeyManager = pauseHK

        let cancelHK = HotkeyManager()
        cancelHK.register(hotkeyString: "ctrl+opt+cmd+esc") { [weak self] in self?.cancelTyping() }
        self.cancelHotkeyManager = cancelHK

        // Optional emergency monitor: double-press ESC or ctrl+opt+cmd+esc (configurable)
        let window = UserDefaults.standard.double(forKey: PreferencesKeys.emergencyCancelDoublePressWindow)
        let monitor = KeyboardEventMonitor(doubleTapWindow: window > 0 ? window : 0.4)
        if UserDefaults.standard.bool(forKey: PreferencesKeys.emergencyCancelEnabled) {
            monitor.onCancel = { [weak self] in self?.cancelTyping() }
        } else {
            monitor.onCancel = nil
        }
        monitor.onStart = { [weak self] in self?.startTypingFromClipboard() }
        monitor.setStartHotkey(from: hotkeyString)
        self.keyboardMonitor = monitor
        monitor.start()

        // Show onboarding if permissions missing
        if !PermissionsManager.hasAccessibilityPermission() || !PermissionsManager.hasInputMonitoringPermission() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.openPermissions()
            }
        }
    }

    // URL scheme handler: clippytyper://start|pause|cancel
    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else { return }
        guard url.scheme?.lowercased() == "clippytyper" else { return }
        let action = url.host?.lowercased() ?? url.path.replacingOccurrences(of: "/", with: "").lowercased()
        switch action {
        case "start": startTypingFromClipboard()
        case "pause": togglePause()
        case "cancel": cancelTyping()
        default: break
        }
    }

    @objc private func handleDistributedStart() { startTypingFromClipboard() }
    @objc private func handleDistributedPauseToggle() { togglePause() }
    @objc private func handleDistributedCancel() { cancelTyping() }

    private func startTypingFromClipboard() {
        guard PermissionsManager.ensureAccessibilityPermission() else {
            PermissionsManager.promptToEnableAccessibility()
            return
        }

        // Respect per-app exceptions
        if let active = NSWorkspace.shared.frontmostApplication?.bundleIdentifier {
            let list = UserDefaults.standard.array(forKey: PreferencesKeys.perAppExceptions) as? [String] ?? []
            if list.contains(active) {
                NSLog("ClippyTyper: Skipping typing for excluded app: \(active)")
                NSSound.beep()
                return
            }
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
            if case .failure(let error) = result {
                NSLog("Typing failed: \(error)")
                if UserDefaults.standard.bool(forKey: PreferencesKeys.instantPasteFallback) {
                    KeyEventUtil.sendCommandV()
                }
            }
        }
    }

    private func excludeCurrentApp() {
        guard let active = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return }
        var list = UserDefaults.standard.array(forKey: PreferencesKeys.perAppExceptions) as? [String] ?? []
        if !list.contains(active) {
            list.append(active)
            UserDefaults.standard.set(list, forKey: PreferencesKeys.perAppExceptions)
            NSLog("ClippyTyper: Added to exclusions: \(active)")
        }
    }

    private func openPreferences() {
        if prefsWindow == nil {
            let vc = PreferencesViewController()
            vc.onTypingSpeedChanged = { _ in /* speed is read on next run; engine uses cps when invoked */ }
            vc.onHotkeyChanged = { [weak self] hotkey in self?.registerHotkey(hotkey) }
            vc.onEmergencyCancelEnabledChanged = { [weak self] enabled in
                guard let self else { return }
                if self.keyboardMonitor == nil {
                    let window = UserDefaults.standard.double(forKey: PreferencesKeys.emergencyCancelDoublePressWindow)
                    let m = KeyboardEventMonitor(doubleTapWindow: window > 0 ? window : 0.4)
                    m.onStart = { [weak self] in self?.startTypingFromClipboard() }
                    m.setStartHotkey(from: UserDefaults.standard.string(forKey: PreferencesKeys.hotkey) ?? "ctrl+opt+t")
                    m.start()
                    self.keyboardMonitor = m
                }
                self.keyboardMonitor?.onCancel = enabled ? { [weak self] in self?.cancelTyping() } : nil
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

    private func openHelp() {
        if helpWindow == nil { helpWindow = HelpWindowController() }
        NSApp.activate(ignoringOtherApps: true)
        helpWindow?.showWindow(nil)
        helpWindow?.window?.makeKeyAndOrderFront(nil)
    }

    private func openPermissions() {
        if permissionsWindow == nil { permissionsWindow = PermissionsWindowController() }
        NSApp.activate(ignoringOtherApps: true)
        permissionsWindow?.showWindow(nil)
        permissionsWindow?.window?.makeKeyAndOrderFront(nil)
    }

    private func registerHotkey(_ hotkeyString: String) {
        if hotkeyManager == nil { hotkeyManager = HotkeyManager() }
        let ok = hotkeyManager?.register(hotkeyString: hotkeyString) { [weak self] in
            self?.startTypingFromClipboard()
        } ?? false
        keyboardMonitor?.setStartHotkey(from: hotkeyString)
        NotificationCenter.default.post(name: .hotkeyRegistrationResult, object: HotkeyRegistrationInfo(success: ok, hotkey: hotkeyString, message: ok ? nil : "Hotkey may be in use by another app or restricted"))
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
