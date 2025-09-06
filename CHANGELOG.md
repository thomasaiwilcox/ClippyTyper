# Changelog

All notable changes to this project will be documented in this file.

## v0.1.1 - 2025-09-06
- Per‑App Exceptions: skip typing in selected apps; manage list in Preferences (add/remove/clear) and via “Exclude Current App” menu.
- Typing Progress: menu bar percentage and floating HUD with pause/cancel hints; updates live, hides on completion/cancel.
- Instant Paste Fallback: fixed behavior to engage only when typing fails; tries AX value insert first, then Cmd+V.
- Login at Login: SMAppService helper target (ClippyTyperHelper) for the bundled Xcode app; LaunchAgent fallback for SwiftPM dev.
- Preferences: larger, resizable window; inline login item status and error feedback.
- CI: moved to self‑hosted runner; kept Xcode build/test and lint; removed unstable SwiftPM job.

## v0.1.0 - 2025-09-06
- Permissions onboarding window + auto-open when missing
- Help panel with Parallels/Citrix guidance
- HID-level start hotkey detection (works when not frontmost)
- CLI tool: `clippyctl start|pause|cancel`
- Xcode project (XcodeGen) + URL scheme `clippytyper://start|pause|cancel` + UI test stub
- Instant-paste fallback option (Cmd+V) on typing failure
- Expanded hotkey parsing + conflict feedback
- Make targets for Xcode gen/build/test; updated docs (README, AGENTS.md)
