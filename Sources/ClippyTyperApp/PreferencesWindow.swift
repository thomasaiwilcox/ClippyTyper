import AppKit
import ClippyTyperPreferences

final class PreferencesWindowController: NSWindowController {
    init(contentViewController: NSViewController) {
        let window = NSWindow(contentViewController: contentViewController)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.title = "Preferences"
        window.setContentSize(NSSize(width: 560, height: 520))
        window.minSize = NSSize(width: 520, height: 420)
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

    private let hotkeyStatusLabel: NSTextField = {
        let tf = NSTextField(labelWithString: "")
        tf.textColor = .secondaryLabelColor
        tf.lineBreakMode = .byTruncatingTail
        return tf
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

    private let instantPasteFallbackCheckbox: NSButton = {
        let b = NSButton(checkboxWithTitle: "Use instant paste fallback when typing fails", target: nil, action: nil)
        return b
    }()

    // Exclusions UI
    private let exclusionsLabel = NSTextField(labelWithString: "Excluded apps (bundle IDs)")
    private let exclusionsScroll = NSScrollView()
    private let exclusionsTable = NSTableView()
    private let excludeCurrentButton = NSButton(title: "Exclude Current App", target: nil, action: nil)
    private let removeSelectedButton = NSButton(title: "Remove Selected", target: nil, action: nil)
    private let clearExclusionsButton = NSButton(title: "Clear All", target: nil, action: nil)
    private var exclusions: [String] = []

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
        instantPasteFallbackCheckbox.state = defaults.bool(forKey: PreferencesKeys.instantPasteFallback) ? .on : .off

        // Build layout
        [speedLabel, speedSlider, speedValueLabel,
         hotkeyLabel, hotkeyField, applyHotkeyButton, hotkeyStatusLabel,
         launchAtLoginCheckbox,
         emergencyCancelCheckbox,
         doublePressLabel, doublePressSlider, doublePressValueLabel,
         instantPasteFallbackCheckbox,
         exclusionsLabel, exclusionsScroll, excludeCurrentButton, removeSelectedButton, clearExclusionsButton].forEach {
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

            hotkeyStatusLabel.topAnchor.constraint(equalTo: hotkeyField.bottomAnchor, constant: 6),
            hotkeyStatusLabel.leadingAnchor.constraint(equalTo: hotkeyField.leadingAnchor),
            hotkeyStatusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            launchAtLoginCheckbox.topAnchor.constraint(equalTo: hotkeyStatusLabel.bottomAnchor, constant: 12),
            launchAtLoginCheckbox.leadingAnchor.constraint(equalTo: speedLabel.leadingAnchor),

            emergencyCancelCheckbox.topAnchor.constraint(equalTo: launchAtLoginCheckbox.bottomAnchor, constant: 12),
            emergencyCancelCheckbox.leadingAnchor.constraint(equalTo: speedLabel.leadingAnchor),

            doublePressLabel.topAnchor.constraint(equalTo: emergencyCancelCheckbox.bottomAnchor, constant: 8),
            doublePressLabel.leadingAnchor.constraint(equalTo: speedLabel.leadingAnchor),

            doublePressSlider.leadingAnchor.constraint(equalTo: doublePressLabel.leadingAnchor),
            doublePressSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            doublePressSlider.topAnchor.constraint(equalTo: doublePressLabel.bottomAnchor, constant: 8),

            doublePressValueLabel.centerYAnchor.constraint(equalTo: doublePressSlider.centerYAnchor),
            doublePressValueLabel.leadingAnchor.constraint(equalTo: doublePressSlider.trailingAnchor, constant: 8),

            instantPasteFallbackCheckbox.topAnchor.constraint(equalTo: doublePressSlider.bottomAnchor, constant: 16),
            instantPasteFallbackCheckbox.leadingAnchor.constraint(equalTo: speedLabel.leadingAnchor),

            exclusionsLabel.topAnchor.constraint(equalTo: instantPasteFallbackCheckbox.bottomAnchor, constant: 16),
            exclusionsLabel.leadingAnchor.constraint(equalTo: speedLabel.leadingAnchor),

            exclusionsScroll.topAnchor.constraint(equalTo: exclusionsLabel.bottomAnchor, constant: 8),
            exclusionsScroll.leadingAnchor.constraint(equalTo: speedLabel.leadingAnchor),
            exclusionsScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            exclusionsScroll.heightAnchor.constraint(equalToConstant: 240),

            excludeCurrentButton.topAnchor.constraint(equalTo: exclusionsScroll.bottomAnchor, constant: 8),
            excludeCurrentButton.leadingAnchor.constraint(equalTo: speedLabel.leadingAnchor),

            removeSelectedButton.centerYAnchor.constraint(equalTo: excludeCurrentButton.centerYAnchor),
            removeSelectedButton.leadingAnchor.constraint(equalTo: excludeCurrentButton.trailingAnchor, constant: 8),

            clearExclusionsButton.centerYAnchor.constraint(equalTo: excludeCurrentButton.centerYAnchor),
            clearExclusionsButton.leadingAnchor.constraint(equalTo: removeSelectedButton.trailingAnchor, constant: 8)
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
        instantPasteFallbackCheckbox.target = self
        instantPasteFallbackCheckbox.action = #selector(onInstantPasteFallbackToggled)

        excludeCurrentButton.target = self
        excludeCurrentButton.action = #selector(onExcludeCurrentApp)
        removeSelectedButton.target = self
        removeSelectedButton.action = #selector(onRemoveSelected)
        clearExclusionsButton.target = self
        clearExclusionsButton.action = #selector(onClearExclusions)

        NotificationCenter.default.addObserver(self, selector: #selector(onHotkeyRegistrationResult(_:)), name: .hotkeyRegistrationResult, object: nil)

        // Exclusions table setup
        setupExclusionsTable()
        loadExclusions()
    }

    @objc private func onInstantPasteFallbackToggled() {
        let enabled = (instantPasteFallbackCheckbox.state == .on)
        UserDefaults.standard.set(enabled, forKey: PreferencesKeys.instantPasteFallback)
    }

    @objc private func onSpeedChanged() {
        let val = Double(Int(speedSlider.doubleValue)) // whole numbers
        speedSlider.doubleValue = val
        speedValueLabel.stringValue = String(Int(val))
        UserDefaults.standard.set(val, forKey: PreferencesKeys.typingSpeed)
        onTypingSpeedChanged?(val)
    }

    @objc private func onHotkeyRegistrationResult(_ note: Notification) {
        guard let info = note.object as? HotkeyRegistrationInfo else { return }
        if info.success {
            hotkeyStatusLabel.stringValue = "Registered: \(info.hotkey)"
            hotkeyStatusLabel.textColor = .secondaryLabelColor
        } else {
            hotkeyStatusLabel.stringValue = info.message ?? "Failed to register hotkey"
            hotkeyStatusLabel.textColor = .systemRed
        }
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

    // MARK: - Exclusions

    private func setupExclusionsTable() {
        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("BundleID"))
        col.title = "Bundle ID"
        col.width = 380
        exclusionsTable.addTableColumn(col)
        exclusionsTable.headerView = nil
        exclusionsTable.usesAlternatingRowBackgroundColors = true
        exclusionsTable.allowsMultipleSelection = true
        exclusionsTable.delegate = self
        exclusionsTable.dataSource = self
        exclusionsScroll.documentView = exclusionsTable
        exclusionsScroll.hasVerticalScroller = true
        exclusionsScroll.borderType = .bezelBorder
    }

    private func loadExclusions() {
        exclusions = (UserDefaults.standard.array(forKey: PreferencesKeys.perAppExceptions) as? [String] ?? [])
        exclusionsTable.reloadData()
    }

    private func saveExclusions() {
        UserDefaults.standard.set(exclusions, forKey: PreferencesKeys.perAppExceptions)
        exclusionsTable.reloadData()
    }

    @objc private func onExcludeCurrentApp() {
        guard let active = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return }
        if !exclusions.contains(active) {
            exclusions.append(active)
            exclusions.sort()
            saveExclusions()
        }
    }

    @objc private func onRemoveSelected() {
        let rows = exclusionsTable.selectedRowIndexes
        guard !rows.isEmpty else { return }
        exclusions = exclusions.enumerated().filter { !rows.contains($0.offset) }.map { $0.element }
        saveExclusions()
    }

    @objc private func onClearExclusions() {
        exclusions.removeAll()
        saveExclusions()
    }
}

extension PreferencesViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int { exclusions.count }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let id = NSUserInterfaceItemIdentifier("Cell")
        let cell = tableView.makeView(withIdentifier: id, owner: self) as? NSTableCellView ?? {
            let v = NSTableCellView()
            v.identifier = id
            let tf = NSTextField(labelWithString: "")
            tf.translatesAutoresizingMaskIntoConstraints = false
            v.addSubview(tf)
            v.textField = tf
            NSLayoutConstraint.activate([
                tf.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 6),
                tf.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -6),
                tf.topAnchor.constraint(equalTo: v.topAnchor, constant: 2),
                tf.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -2)
            ])
            return v
        }()
        cell.textField?.stringValue = exclusions[row]
        return cell
    }
}
