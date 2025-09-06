import AppKit

final class PermissionsWindowController: NSWindowController {
    init() {
        let vc = PermissionsViewController()
        let window = NSWindow(contentViewController: vc)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.title = "Permissions"
        window.setContentSize(NSSize(width: 520, height: 260))
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class PermissionsViewController: NSViewController {
    private let accLabel = NSTextField(labelWithString: "Accessibility: ")
    private let accStatus = NSTextField(labelWithString: "")
    private let accButton = NSButton(title: "Open Accessibility Settings", target: nil, action: nil)

    private let imLabel = NSTextField(labelWithString: "Input Monitoring: ")
    private let imStatus = NSTextField(labelWithString: "")
    private let imButton = NSButton(title: "Open Input Monitoring Settings", target: nil, action: nil)

    private let refreshButton = NSButton(title: "Check Again", target: nil, action: nil)

    override func loadView() { self.view = NSView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        [accLabel, accStatus, accButton, imLabel, imStatus, imButton, refreshButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        accLabel.font = .boldSystemFont(ofSize: 13)
        imLabel.font = .boldSystemFont(ofSize: 13)

        NSLayoutConstraint.activate([
            accLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            accLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            accStatus.centerYAnchor.constraint(equalTo: accLabel.centerYAnchor),
            accStatus.leadingAnchor.constraint(equalTo: accLabel.trailingAnchor, constant: 6),
            accButton.topAnchor.constraint(equalTo: accLabel.bottomAnchor, constant: 8),
            accButton.leadingAnchor.constraint(equalTo: accLabel.leadingAnchor),

            imLabel.topAnchor.constraint(equalTo: accButton.bottomAnchor, constant: 20),
            imLabel.leadingAnchor.constraint(equalTo: accLabel.leadingAnchor),
            imStatus.centerYAnchor.constraint(equalTo: imLabel.centerYAnchor),
            imStatus.leadingAnchor.constraint(equalTo: imLabel.trailingAnchor, constant: 6),
            imButton.topAnchor.constraint(equalTo: imLabel.bottomAnchor, constant: 8),
            imButton.leadingAnchor.constraint(equalTo: accLabel.leadingAnchor),

            refreshButton.topAnchor.constraint(equalTo: imButton.bottomAnchor, constant: 20),
            refreshButton.leadingAnchor.constraint(equalTo: accLabel.leadingAnchor),
        ])

        accButton.target = self
        accButton.action = #selector(openAccessibility)
        imButton.target = self
        imButton.action = #selector(openInputMonitoring)
        refreshButton.target = self
        refreshButton.action = #selector(refresh)

        refresh()
    }

    @objc private func openAccessibility() {
        PermissionsManager.openAccessibilitySettings()
    }

    @objc private func openInputMonitoring() {
        PermissionsManager.openInputMonitoringSettings()
    }

    @objc private func refresh() {
        set(status: PermissionsManager.hasAccessibilityPermission(), for: accStatus)
        set(status: PermissionsManager.hasInputMonitoringPermission(), for: imStatus)
    }

    private func set(status: Bool, for label: NSTextField) {
        label.stringValue = status ? "Granted" : "Missing"
        label.textColor = status ? .systemGreen : .systemRed
    }
}

