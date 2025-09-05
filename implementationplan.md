# Implementation Plan

This living plan tracks ClippyTyper’s implementation against the PRD. Update it with every meaningful change (check off tasks, add dates, and link PRs).

## Objective
Deliver a macOS Sonoma-focused menu bar utility that types plain-text clipboard contents into the active app via Accessibility APIs, with reliable speed control and minimal resource usage.

## Milestones
- Foundation & Tooling — Completed (2025-09-05)
- Core Typing Engine — Planned
- Hotkey & Routing — Planned
- Menu Bar UI — Planned
- Permissions & Onboarding — Planned
- Preferences UI — Planned
- Advanced Features (pause/cancel, instant paste, per-app exceptions) — Planned
- Performance & QA — Planned
- Packaging & Release — Planned

## Linking Conventions
- Use inline tags to cross-reference work: `[PR: #123]`, `[Issue: #45]`, `[Commit: abc1234]`.
- Optionally add URLs: `https://github.com/<org>/<repo>/pull/123`.
- Example: `- [x] TypingEngine MVP [PR: #12] [Commit: 1a2b3c4] (2025-09-10)`.

## Task Tracker
- [x] Contributor guide (AGENTS.md) aligned with PRD [PR: #___] [Commit: ___]
- [x] Makefile (`make build/test/lint/help`) [PR: #___] [Commit: ___]
- [x] Lint script (`Scripts/lint.sh`) [PR: #___] [Commit: ___]
- [x] Preferences keys/defaults (`ClippyTyper/Preferences/*`) [PR: #___] [Commit: ___]
- [x] Core logic package (SwiftPM) scaffolding: `ClippyTyperCore` [PR: #___] [Commit: ___]
- [x] Unit tests for planning/tokenization and sending order [PR: #___] [Commit: ___]
- [x] App skeleton and wiring (`AppDelegate`, `MenuBarController`, permissions check, pasteboard read) [PR: #___] [Commit: ___]
- [x] Keystroke sender (CGEvent-based) with AX permission check [PR: #___] [Commit: ___]
- [x] TypingEngine: cps planning and retry/backoff on send failures [PR: #___] [Commit: ___]
- [ ] TypingEngine: pasteboard read + integration tests [PR: #___]
- [ ] Unit tests: multiline, emoji/special chars, >10k chars, cps accuracy [PR: #___]
- [x] HotkeyManager: global shortcut registration, default from prefs [PR: #___] [Commit: ___]
- [ ] Hotkey conflict surfacing + Preferences binding [PR: #___]
- [ ] UI tests: shortcut triggers typing; pause/cancel when implemented [PR: #___]
- [ ] MenuBarController: `NSStatusItem` with Start/Pause/Cancel/Preferences [PR: #___]
- [ ] PermissionsManager: Accessibility permission check + guided enablement [PR: #___]
- [ ] Preferences UI: typing speed, hotkey, launch at login [PR: #___]
- [ ] Launch at login integration [PR: #___]
- [ ] Instant paste fallback (optional) [PR: #___]
- [ ] Pause/resume and cancel shortcuts [PR: #___]
- [ ] Per-app exceptions by bundle id (optional) [PR: #___]
- [ ] Performance validation: idle CPU/mem, large text reliability [PR: #___]
- [ ] Packaging: entitlements, codesign, notarization (as applicable) [PR: #___]
- [ ] Release notes and screenshots/GIFs [PR: #___]

## Working Notes
- Keep plain text only; no clipboard history or rich text.
- Target Sonoma; test Ventura/Monterey where feasible.
- No network access; avoid persisting clipboard data.

## Change Log
- 2025-09-05: Initialized plan; added AGENTS.md, Makefile, lint script, and Preferences defaults/keys. [PR: #___]
