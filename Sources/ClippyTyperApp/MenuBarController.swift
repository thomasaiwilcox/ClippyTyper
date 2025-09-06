import AppKit

final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem

    var onStartTyping: (() -> Void)?
    var onPauseResume: (() -> Void)?
    var onCancel: (() -> Void)?
    var onOpenPreferences: (() -> Void)?
    var onOpenHelp: (() -> Void)?
    var onOpenPermissions: (() -> Void)?
    var onQuit: (() -> Void)?

    private var pauseItem: NSMenuItem!

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        constructMenu()
    }

    private func constructMenu() {
        if let button = statusItem.button {
            button.title = "Clippy"
            button.setAccessibilityLabel("ClippyTyper")
        }
        let menu = NSMenu()
        let startItem = NSMenuItem(title: "Start Typing", action: #selector(startTyping), keyEquivalent: "t")
        startItem.target = self
        menu.addItem(startItem)

        menu.addItem(NSMenuItem.separator())

        pauseItem = NSMenuItem(title: "Pause Typing", action: #selector(pauseResume), keyEquivalent: "p")
        pauseItem.target = self
        menu.addItem(pauseItem)

        let cancelItem = NSMenuItem(title: "Cancel Typing", action: #selector(cancelTyping), keyEquivalent: "c")
        cancelItem.target = self
        menu.addItem(cancelItem)

        menu.addItem(NSMenuItem.separator())

        let prefsItem = NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        let permsItem = NSMenuItem(title: "Permissions…", action: #selector(openPermissions), keyEquivalent: "")
        permsItem.target = self
        menu.addItem(permsItem)

        let helpItem = NSMenuItem(title: "Help", action: #selector(openHelp), keyEquivalent: "?")
        helpItem.keyEquivalentModifierMask = [.command]
        helpItem.target = self
        menu.addItem(helpItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    @objc private func startTyping() { onStartTyping?() }
    @objc private func pauseResume() { onPauseResume?() }
    @objc private func cancelTyping() { onCancel?() }
    @objc private func openPreferences() { onOpenPreferences?() }
    @objc private func openPermissions() { onOpenPermissions?() }
    @objc private func openHelp() { onOpenHelp?() }
    @objc private func quitApp() { onQuit?() }

    func setPaused(_ paused: Bool) {
        pauseItem.title = paused ? "Resume Typing" : "Pause Typing"
    }
}
