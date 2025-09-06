import AppKit

final class ProgressHUD: NSWindowController {
    private let titleLabel = NSTextField(labelWithString: "Typing… 0%")
    private let statusLabel = NSTextField(labelWithString: "")

    init() {
        let content = NSView()
        content.wantsLayer = true
        content.layer?.cornerRadius = 12
        content.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.9).cgColor

        let window = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 260, height: 120),
                             styleMask: [.titled, .fullSizeContentView],
                             backing: .buffered,
                             defer: false)
        window.isMovableByWindowBackground = true
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.level = .floating
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.contentView = content

        super.init(window: window)

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.alignment = .center
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.alignment = .center

        [titleLabel, statusLabel].forEach { v in
            v.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(v)
        }

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: content.centerYAnchor, constant: -12),

            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            statusLabel.centerXAnchor.constraint(equalTo: content.centerXAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show() {
        guard let screen = NSScreen.main else { window?.makeKeyAndOrderFront(nil); return }
        if let w = window {
            let frame = w.frame
            let x = screen.frame.midX - frame.width / 2
            let y = screen.frame.midY - frame.height / 2
            w.setFrameOrigin(NSPoint(x: x, y: y))
            w.makeKeyAndOrderFront(nil)
        }
    }

    func hide() {
        window?.orderOut(nil)
    }

    func update(progress fraction: Double?, paused: Bool) {
        if let f = fraction {
            let pct = Int((f * 100).rounded())
            titleLabel.stringValue = paused ? "Paused… \(pct)%" : "Typing… \(pct)%"
        } else {
            titleLabel.stringValue = paused ? "Paused" : "Typing…"
        }
        statusLabel.stringValue = "Press ctrl+opt+esc to pause, ctrl+opt+cmd+esc to cancel"
    }
}

