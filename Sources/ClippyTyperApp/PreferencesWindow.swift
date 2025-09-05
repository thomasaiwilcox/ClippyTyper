import AppKit
import ClippyTyperPreferences

final class PreferencesWindowController: NSWindowController {
    init(contentViewController: NSViewController) {
        let window = NSWindow(contentViewController: contentViewController)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.title = "Preferences"
        window.setContentSize(NSSize(width: 440, height: 320))
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class PreferencesViewController: NSViewController {
    private let speedSlider = NSSlider(value: 15, minValue: 1, maxValue: 60, target: nil, action: nil)
    private let speedLabel = NSTextField(labelWithString: "Typing speed (chars/sec)")
    private let speedValueLabel = NSTextField(labelWithString: "15")

    private let hotkeyLabel = NSTextField(labelWithString: "Global hotkey")
    private let hotkeyField: NSTextField = {
        let tf = NSTextField(string: "")
        tf.placeholderString = "ctrl+opt+t"
        return tf
    }()
    private let applyHotkeyButton: NSButton = {
        let b = NSButton(title: "Apply Hotkey", target: nil, action: nil)
        b.bezelStyle = .rounded
        return b
    }()

    private let launchAtLoginCheckbox: NSButton = {
        let b = NSButton(checkboxWithTitle: "Launch at login", target: nil, action: nil)
        return b
    }()

    private let emergencyCancelCheckbox: NSButton = {
        let b = NSButton(checkboxWithTitle: "Enable emergency cancel (Esc×2 / ctrl+opt+cmd+Esc)", target: nil, action: nil)
        return b
    }()

    private let doublePressLabel = NSTextField(labelWithString: "Double‑press window (seconds)")
    private let doublePressSlider = NSSlider(value: 0.4, minValue: 0.2, maxValue: 1.0, target: nil, action: nil)
    private let doublePressValueLabel = NSTextField(labelWithString: "0.4")

    var onTypingSpeedChanged: ((Double) -> Void)?
    var onHotkeyChanged: ((String) -> Void)?
    var onLaunchAtLoginChanged: ((Bool) -> Void)?
    var onEmergencyCancelEnabledChanged: ((Bool) -> Void)?
    var onDoublePressWindowChanged: ((Double) -> Void)?

    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Read current defaults
        let defaults = UserDefaults.standard
        let currentSpeed = defaults.double(forKey: PreferencesKeys.typingSpeed)
        speedSlider.doubleValue = currentSpeed > 0 ? currentSpeed : 15
        speedValueLabel.stringValue = String(Int(speedSlider.doubleValue))
        let currentHotkey = defaults.string(forKey: PreferencesKeys.hotkey) ?? "ctrl+opt+t"
        hotkeyField.stringValue = currentHotkey
        // Prefer actual system state; fall back to stored pref
        let sysEnabled = LaunchAtLoginManager.isEnabled()
        launchAtLoginCheckbox.state = sysEnabled ? .on : (defaults.bool(forKey: PreferencesKeys.launchAtLogin) ? .on : .off)
        emergencyCancelCheckbox.state = defaults.bool(forKey: PreferencesKeys.emergencyCancelEnabled) ? .on : .off
        let dpw = defaults.double(forKey: PreferencesKeys.emergencyCancelDoublePressWindow)
        doublePressSlider.doubleValue = (dpw > 0 ? dpw : 0.4)
        doublePressValueLabel.stringValue = String(format: "%.1f", doublePressSlider.doubleValue)

        // Build layout
        [speedLabel, speedSlider, speedValueLabel, hotkeyLabel, hotkeyField, applyHotkeyButton, launchAtLoginCheckbox, emergencyCancelCheckbox, doublePressLabel, doublePressSlider, doublePressValueLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            speedLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            speedLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            speedSlider.leadingAnchor.constraint(equalTo: speedLabel.leadingAnchor),
            speedSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            speedSlider.topAnchor.constraint(equalTo: speedLabel.bottomAnchor, constant: 8),

            speedValueLabel.centerYAnchor.constraint(equalTo: speedSlider.centerYAnchor),
            speedValueLabel.leadingAnchor.constraint(equalTo: speedSlider.trailingAnchor, constant: 8),

            hotkeyLabel.topAnchor.constraint(equalTo: speedSlider.bottomAnchor, constant: 20),
            hotkeyLabel.leadingAnchor.constraint(equalTo: speedLabel.leadingAnchor),

            hotkeyField.leadingAnchor.constraint(equalTo: hotkeyLabel.leadingAnchor),
            hotkeyField.widthAnchor.constraint(equalToConstant: 220),
            hotkeyField.topAnchor.constraint(equalTo: hotkeyLabel.bottomAnchor, constant: 8),

            applyHotkeyButton.centerYAnchor.constraint(equalTo: hotkeyField.centerYAnchor),
            applyHotkeyButton.leadingAnchor.constraint(equalTo: hotkeyField.trailingAnchor, constant: 8),

            launchAtLoginCheckbox.topAnchor.constraint(equalTo: hotkeyField.bottomAnchor, constant: 16),
            launchAtLoginCheckbox.leadingAnchor.constraint(equalTo: speedLabel.leadingAnchor),

            emergencyCancelCheckbox.topAnchor.constraint(equalTo: launchAtLoginCheckbox.bottomAnchor, constant: 12),
            emergencyCancelCheckbox.leadingAnchor.constraint(equalTo: speedLabel.leadingAnchor),

            doublePressLabel.topAnchor.constraint(equalTo: emergencyCancelCheckbox.bottomAnchor, constant: 8),
            doublePressLabel.leadingAnchor.constraint(equalTo: speedLabel.leadingAnchor),

            doublePressSlider.leadingAnchor.constraint(equalTo: doublePressLabel.leadingAnchor),
            doublePressSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            doublePressSlider.topAnchor.constraint(equalTo: doublePressLabel.bottomAnchor, constant: 8),

            doublePressValueLabel.centerYAnchor.constraint(equalTo: doublePressSlider.centerYAnchor),
            doublePressValueLabel.leadingAnchor.constraint(equalTo: doublePressSlider.trailingAnchor, constant: 8)
        ])

        // Wire actions
        speedSlider.target = self
        speedSlider.action = #selector(onSpeedChanged)
        applyHotkeyButton.target = self
        applyHotkeyButton.action = #selector(applyHotkey)
        launchAtLoginCheckbox.target = self
        launchAtLoginCheckbox.action = #selector(onLaunchAtLoginToggled)
        emergencyCancelCheckbox.target = self
        emergencyCancelCheckbox.action = #selector(onEmergencyCancelToggled)
        doublePressSlider.target = self
        doublePressSlider.action = #selector(onDoublePressWindowSliderChanged)
    }

    @objc private func onSpeedChanged() {
        let val = Double(Int(speedSlider.doubleValue)) // whole numbers
        speedSlider.doubleValue = val
        speedValueLabel.stringValue = String(Int(val))
        UserDefaults.standard.set(val, forKey: PreferencesKeys.typingSpeed)
        onTypingSpeedChanged?(val)
    }

    @objc private func applyHotkey() {
        let text = hotkeyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        UserDefaults.standard.set(text, forKey: PreferencesKeys.hotkey)
        onHotkeyChanged?(text)
    }

    @objc private func onLaunchAtLoginToggled() {
        let enabled = (launchAtLoginCheckbox.state == .on)
        do {
            try LaunchAtLoginManager.setEnabled(enabled)
            UserDefaults.standard.set(enabled, forKey: PreferencesKeys.launchAtLogin)
            onLaunchAtLoginChanged?(enabled)
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Failed to update Launch at Login"
            alert.informativeText = String(describing: error)
            alert.addButton(withTitle: "OK")
            alert.runModal()
            launchAtLoginCheckbox.state = LaunchAtLoginManager.isEnabled() ? .on : .off
        }
    }

    @objc private func onEmergencyCancelToggled() {
        let enabled = (emergencyCancelCheckbox.state == .on)
        UserDefaults.standard.set(enabled, forKey: PreferencesKeys.emergencyCancelEnabled)
        onEmergencyCancelEnabledChanged?(enabled)
    }

    @objc private func onDoublePressWindowSliderChanged() {
        let val = (round(doublePressSlider.doubleValue * 10) / 10) // step 0.1
        doublePressSlider.doubleValue = val
        doublePressValueLabel.stringValue = String(format: "%.1f", val)
        UserDefaults.standard.set(val, forKey: PreferencesKeys.emergencyCancelDoublePressWindow)
        onDoublePressWindowChanged?(val)
    }
}
