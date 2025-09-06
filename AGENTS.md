# Repository Guidelines

Targets a macOS AppKit menu bar utility that types clipboard text via Accessibility APIs. Follow the PRD for scope: macOS Sonoma primary (aim to support Ventura/Monterey), plain text only, minimal resource usage.

## Project Structure & Module Organization
- `ClippyTyper/`: Sources (AppKit UI, AX typing engine, Pasteboard integration).
- `ClippyTyperTests/`: Unit tests (XCTest).
- `ClippyTyperUITests/`: UI tests (menu bar, shortcuts).
- `PRD.md`: Product spec (read first).
- SwiftPM core: `Sources/ClippyTyperCore/` and `Tests/ClippyTyperCoreTests/` for the core typing logic and unit tests.
- SwiftPM app: `Sources/ClippyTyperApp/` (menu bar skeleton, wiring to core).

## Build, Test, and Development Commands
- Discover commands: `make help`.
- Open in Xcode: `open ClippyTyper.xcodeproj` (or `.xcworkspace`).
- Make targets: `make build`, `make test`, `make lint` (override with `SCHEME=…`).
- Direct Xcode: `xcodebuild -scheme ClippyTyper -configuration Debug -destination 'platform=macOS' build`.
- Tests (direct): `xcodebuild -scheme ClippyTyper -destination 'platform=macOS' test`.
- Core library (SwiftPM): `swift build` and `swift test` for `ClippyTyperCore`.
- Run skeleton app (SwiftPM): `swift run ClippyTyperApp` (Status bar shows "Clippy"). Uses `CGEvent` to emit keystrokes; requires Accessibility permission.
- Preferences: open from the menu to change typing speed and global hotkey; updates apply immediately and hotkey re-registers live. Toggle emergency cancel and adjust double‑press window. Launch at login uses a user LaunchAgent during SPM development; a bundled login helper can be added for releases.
 - Permissions: open from the menu to review Accessibility/Input Monitoring status and jump to System Settings. The app auto-opens this if a required permission is missing at launch.
- Controls: Menu provides Start, Pause/Resume, Cancel. Hotkeys: typing (from prefs), pause (`ctrl+opt+esc`), cancel (`ctrl+opt+cmd+esc`).
- Hotkeys: parser supports letters, digits, punctuation, arrows, function keys, and named keys (e.g., `cmd+shift+f12`). Preferences show status if registration fails (likely conflict).
 - CLI control: `swift run clippyctl start|pause|cancel` posts a distributed notification to the running app (useful for Stream Deck/Alfred). For a URL scheme, add CFBundleURLTypes when migrating to an Xcode app bundle.
 - Per‑App Exceptions: from the menu, choose “Exclude Current App” to add the frontmost app’s bundle ID to the skip list. ClippyTyper will not type when that app is active. Manage the list (basic) in Preferences in a future iteration.

## CI (GitHub Actions)
- Workflow: `.github/workflows/ci.yml` runs on pushes and PRs to `main` and `release/**`.
- Jobs:
  - Build & Test (SwiftPM): `swift build` and `swift test` on `macos-13`.
  - Lint (optional): installs `swiftformat`/`swiftlint` via Homebrew and runs `Scripts/lint.sh`.
  - Build (Xcode): generates with XcodeGen and builds the `ClippyTyper` scheme.
  - Test (Xcode, best-effort): runs `xcodebuild … test`; marked continue-on-error since UI automation can be restricted on runners.
- View status: `gh run list` and open checks in the PR UI; rerun with `gh run rerun <id>`.

## Coding Style & Naming Conventions
- Swift 5+, Swift API Design Guidelines; 4-space indent; ~120 col width.
- Names: Types `PascalCase` (e.g., `TypingEngine`), methods/vars `camelCase`.
- Structure files with `// MARK:`; use `swiftformat`/`swiftlint` if configured.

## Testing Guidelines
- Framework: XCTest. Cover AX typing, hotkey routing, and Pasteboard reads; aim ≥80% where practical.
- Scenarios: multiline, emoji/special characters, large text (>10k chars), typing speed accuracy, and cancel/pause when implemented.
- UI: Verify global shortcut triggers and menu actions.

## Commit & Pull Request Guidelines
- Commits: Conventional Commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`). Keep small and scoped.
- Branches: `feature/<short-desc>` or `fix/<issue-#>` (e.g., `feature/typing-speed-pref`).
- PRs: Include description, linked issues, screenshots/GIFs, notes on permissions/entitlements, and a short manual test checklist.

## GitHub CLI
- Install: `brew install gh`; authenticate: `gh auth login` (grants gh and git access).
- Repo: `gh repo view` shows current; `gh browse` opens it in a browser; set default with `gh repo set-default <owner>/<repo>` if needed.
- Branch & push: `git switch -c feature/<name>` → work → `git add -A && git commit -m "feat: ..." && git push -u origin HEAD`.
- Pull requests: `gh pr create --fill` (or `-t <title> -b <body>`), then `gh pr view --web`; merge with `gh pr merge --squash --delete-branch`.
- Issues: `gh issue create -t "Title" -b "Details"` and link in PRs; status with `gh status`.
- Releases: `gh release create v1.0.0 <zip|dmg> -t "Title" -n "Notes"`.
- Link plan: include `[PR: #<num>]`/`[Issue: #<num>]` in `implementationplan.md`; update after merge.
- Help: `gh <command> <subcommand> --help` and manual: https://cli.github.com/manual

## Planning & Tracking
- Implementation plan: keep `implementationplan.md` updated (check off tasks, add dates, and link PRs/commits).
- Use link tags in tasks: `[PR: #123]`, `[Issue: #45]`, `[Commit: abc1234]` (add URLs if helpful).
- New PRs: reference the specific tasks in `implementationplan.md` you are completing.
- After merge: update the plan status and append a brief change-log entry.

## Architecture Overview
- TypingEngine: Reads `NSPasteboard` plain text and dispatches keystrokes via Accessibility (AXUIElement). Enforces characters-per-second; plan for pause/cancel and instant-paste fallback per PRD.
- HotkeyManager: Registers a global shortcut, debounces repeats, and routes to `TypingEngine`. Surface conflicts in Preferences.
- MenuBarController: `NSStatusItem` with actions (Start Typing, Pause/Cancel, Preferences) and status indicators.
- PermissionsManager: Checks Accessibility permission on launch and exposes a guided “Enable Accessibility” flow if missing.
- PreferencesStore: `UserDefaults` for `typingSpeed`, `hotkey`, and `launchAtLogin`. Keys live in `ClippyTyper/Preferences/UserDefaultsKeys.swift`; defaults in `ClippyTyper/Preferences/RegisterDefaults.swift` (call `PreferencesDefaults.register()` at launch). Apply changes live.
- App Wiring: `AppDelegate` composes the above components; keep UI work on main thread and typing scheduling off the main thread.

## Security, Permissions & Performance
- Accessibility permission required: System Settings → Privacy & Security → Accessibility; add the built app.
- Input Monitoring: enabling emergency cancel also enables HID-level hotkey detection for starting; grant Input Monitoring to improve reliability when ClippyTyper is not frontmost.
 - When running via `swift run`, macOS may attribute Input Monitoring to your terminal (Terminal/iTerm). Grant Input Monitoring to that terminal app to allow the HID listener to function.
- No network access; do not store clipboard contents beyond the session.
- Reset perms during dev: `tccutil reset Accessibility <bundle-id>`.
- Performance: keep idle CPU/memory negligible; ensure reliable typing at configured speed.
 - Optional: Reliable cancel uses a keyboard event tap (double-press Esc or ctrl+opt+cmd+Esc). macOS may prompt for Input Monitoring permission if enabled.

## VM/Citrix Notes
- Some full-screen apps (VMs, Citrix) can capture the keyboard before macOS sees it. In those cases, no app can register a global hotkey. Mitigations:
  - Choose a host-reserved combo (e.g., `cmd+shift+F16` or F16–F19) and configure your VM/Citrix to pass it to macOS.
  - In VM settings, disable “Capture macOS shortcuts” for your chosen combo, or map a “host key” that forwards to macOS.
  - Keep the menu bar visible and use the Clippy icon when hotkeys are blocked.
  - Alternatively, trigger via `clippyctl start` from the host.
- Xcode project: optional via XcodeGen.
  - Easiest: `make xcode` (runs XcodeGen and opens the project).
  - Or manually: `cd xcode && xcodegen generate && open ClippyTyper.xcodeproj`.
  - Build via Xcode: `make xcode-build` (uses scheme `ClippyTyper`; override with `XCODE_SCHEME=…`).
  - Test via Xcode: `make xcode-test` (runs the scheme’s test action; UI tests require enabling automation permissions).
  - The app target registers the URL scheme `clippytyper://<action>` (actions: `start`, `pause`, `cancel`).
  - Example: `open 'clippytyper://start'` to trigger from the host.
