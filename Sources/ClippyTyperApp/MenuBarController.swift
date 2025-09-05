import AppKit

final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem

    var onStartTyping: (() -> Void)?
    var onOpenPreferences: (() -> Void)?
    var onQuit: (() -> Void)?

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

        let prefsItem = NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    @objc private func startTyping() { onStartTyping?() }
    @objc private func openPreferences() { onOpenPreferences?() }
    @objc private func quitApp() { onQuit?() }
}
