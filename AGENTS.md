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
- No network access; do not store clipboard contents beyond the session.
- Reset perms during dev: `tccutil reset Accessibility <bundle-id>`.
- Performance: keep idle CPU/memory negligible; ensure reliable typing at configured speed.
