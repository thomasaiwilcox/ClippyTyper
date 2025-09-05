# Implementation Plan

This living plan tracks ClippyTyper’s implementation against the PRD. Update it with every meaningful change (check off tasks, add dates, and link PRs).

## Objective
Deliver a macOS Sonoma-focused menu bar utility that types plain-text clipboard contents into the active app via Accessibility APIs, with reliable speed control and minimal resource usage.

## Milestones
- Foundation & Tooling — Completed (2025-09-05)
- Core Typing Engine — In progress
- Hotkey & Routing — Completed (basic)
- Menu Bar UI — In progress (Start/Preferences/ Quit; Pause/Cancel pending)
- Permissions & Onboarding — In progress (check + prompt)
- Preferences UI — Completed (speed + hotkey)
- Advanced Features (pause/cancel, instant paste, per-app exceptions) — Planned
- Performance & QA — Planned
- Packaging & Release — Planned

## Linking Conventions
- Use inline tags to cross-reference work: `[PR: #123]`, `[Issue: #45]`, `[Commit: abc1234]`.
- Optionally add URLs: `https://github.com/<org>/<repo>/pull/123`.
- Example: `- [x] TypingEngine MVP [PR: #12] [Commit: 1a2b3c4] (2025-09-10)`.

- [x] Contributor guide (AGENTS.md) aligned with PRD [PR: #___] [Commit: ___] (2025-09-05)
- [x] Makefile (`make build/test/lint/help`) [PR: #___] [Commit: ___] (2025-09-05)
- [x] Lint script (`Scripts/lint.sh`) [PR: #___] [Commit: ___] (2025-09-05)
- [x] Preferences keys/defaults (`ClippyTyper/Preferences/*`) [PR: #___] [Commit: ___] (2025-09-05)
- [x] Core logic package (SwiftPM) scaffolding: `ClippyTyperCore` [PR: #___] [Commit: ___] (2025-09-05)
- [x] Unit tests for planning/tokenization and sending order [PR: #___] [Commit: ___] (2025-09-05)
- [x] App skeleton and wiring (`AppDelegate`, `MenuBarController`, permissions check, pasteboard read) [PR: #___] [Commit: ___] (2025-09-05)
- [x] Keystroke sender (CGEvent-based) with AX permission check [PR: #___] [Commit: ___] (2025-09-05)
- [x] TypingEngine: cps planning and retry/backoff on send failures [PR: #___] [Commit: ___] (2025-09-05)
- [x] Pasteboard read on invoke (AppDelegate) [PR: #___] [Commit: ___]
- [ ] Integration tests/harness for end-to-end typing (optional) [PR: #___]
- [ ] Unit tests: multiline, emoji/special chars, >10k chars, cps accuracy [PR: #___]
- [x] HotkeyManager: global shortcut registration, default from prefs [PR: #___] [Commit: ___] (2025-09-05)
- [ ] Hotkey conflict surfacing + Preferences binding [PR: #___]
- [x] Preferences UI: typing speed + hotkey (live apply); store launch-at-login [PR: #___] [Commit: ___] (2025-09-05)
- [x] Preferences: emergency cancel toggle + double-press window [PR: #___] [Commit: ___] (2025-09-05)
- [x] Launch at login integration (LaunchAgent while on SPM; migrate to SMAppService with helper when bundling) [PR: #___] [Commit: ___] (2025-09-05)
- [ ] UI tests: shortcut triggers typing; pause/cancel when implemented [PR: #___]
- [x] MenuBarController: Pause/Cancel actions [PR: #___] [Commit: ___] (2025-09-05)
- [ ] Permissions onboarding flow (guided UI) [PR: #___]
- [ ] Instant paste fallback (optional) [PR: #___]
- [x] Pause/resume and cancel shortcuts [PR: #___] [Commit: ___] (2025-09-05)
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
- 2025-09-05: Added core SPM lib + tests; menu bar skeleton; AX/CGEvent keystroke sender; global hotkey; Preferences UI; pasteboard read; retry/backoff in TypingEngine. [PR: #___]
