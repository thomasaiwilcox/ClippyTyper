import AppKit

final class HelpWindowController: NSWindowController {
    init() {
        let textView = NSTextView(frame: .zero)
        textView.isEditable = false
        textView.string = HelpWindowController.helpText
        textView.textContainerInset = NSSize(width: 8, height: 8)

        let scroll = NSScrollView(frame: .zero)
        scroll.hasVerticalScroller = true
        scroll.documentView = textView

        let vc = NSViewController()
        vc.view = scroll

        let window = NSWindow(contentViewController: vc)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.title = "ClippyTyper Help"
        window.setContentSize(NSSize(width: 520, height: 420))
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private static let helpText: String = {
        return """
        Global Hotkeys & Permissions
        - Accessibility: Required for typing via CGEvent.
        - Input Monitoring: Enables reliable detection of hotkeys when ClippyTyper is not frontmost (HID listener).
        - When running via `swift run`, grant Input Monitoring to your terminal (Terminal/iTerm).

        Parallels (Windows VM) Full‑Screen Tips
        - Some VMs capture the keyboard before macOS, blocking hotkeys.
        - In Parallels → VM Settings → Options → Shortcuts:
          • Send macOS system shortcuts: Always
          • Add a custom shortcut (e.g., cmd+shift+F16) and set to Do nothing in Windows
        - Options → Advanced: Turn OFF “Optimize for games”.
        - Prefer uncommon host combos (F16–F19, cmd+shift+F16).

        Citrix/Remote Desktop
        - Configure the client to pass your chosen combo to macOS.
        - Prefer an uncommon combo to avoid interception by the remote session.

        Alternatives to Hotkeys
        - Menu bar: Click the Clippy icon to start/pause/cancel.
        - CLI: Use `clippyctl start|pause|cancel` to control Clippy from scripts, Stream Deck, or Alfred.
        """
    }()
}

