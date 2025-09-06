# ClippyTyper

[![CI](https://github.com/thomasaiwilcox/ClippyTyper/actions/workflows/ci.yml/badge.svg)](https://github.com/thomasaiwilcox/ClippyTyper/actions/workflows/ci.yml)

A lightweight macOS utility that types the current clipboard text into the active application by simulating keystrokes. Designed for reliability, low resource usage, and fast control via a global hotkey, menu bar, CLI, or URL scheme.

## Features
- Simulated typing (UTF‑8, emoji, newlines) with configurable speed.
- Global hotkey (default `ctrl+opt+t`), Pause (`ctrl+opt+esc`), Cancel (`ctrl+opt+cmd+esc`).
- Emergency cancel (double‑press Esc) and HID‑level hotkey detection for background use.
- Preferences: hotkey, typing speed, launch at login (dev via LaunchAgent), emergency cancel window, instant‑paste fallback.
- CLI control: `clippyctl start|pause|cancel`.
- URL scheme (Xcode app): `clippytyper://start|pause|cancel`.

## Requirements
- macOS Sonoma (aims to work on Ventura/Monterey).
- Accessibility permission (typing) and Input Monitoring (reliable background hotkeys).
- Swift toolchain or Xcode (for building/running).

## Quick Start
- SwiftPM run: `swift run ClippyTyperApp`
- CLI trigger: `swift run clippyctl start` (or `pause`/`cancel`)
- Make targets: `make build`, `make test`, `make xcode`, `make xcode-build`, `make xcode-test`
- Xcode project (optional): `make xcode` → opens project with URL scheme support.

Grant permissions in System Settings → Privacy & Security:
- Accessibility: allow ClippyTyper (and your terminal if running via `swift run`).
- Input Monitoring: allow ClippyTyper (and your terminal) for background hotkeys and emergency cancel.

## Usage
1) Copy text to the clipboard.
2) Trigger typing via the global hotkey, the menu bar (Clippy icon → Start), CLI (`clippyctl start`), or `open 'clippytyper://start'` (Xcode app).
3) Pause/resume with `ctrl+opt+esc`; cancel with `ctrl+opt+cmd+esc` or double‑press Esc.

Preferences let you change hotkey, set typing speed (chars/sec), enable launch at login (LaunchAgent while developing), toggle emergency cancel and its double‑press window, and enable instant‑paste fallback.

## Full‑Screen VM/Citrix Tips
Some apps capture the keyboard before macOS sees it. In Parallels: Options → Shortcuts → Send macOS system shortcuts: Always; set a host‑only combo (e.g., `cmd+shift+F16`) to “Do nothing” in Windows; turn off “Optimize for games”. As a fallback, use the menu bar or `clippyctl start` from the host.

## Project Structure
- `Sources/ClippyTyperApp/`: AppKit menu bar app and wiring
- `Sources/ClippyTyperCore/`: Core typing engine (planning, delays)
- `Sources/ClippyTyperAppSupport/`: Hotkey manager and helpers
- `Sources/clippyctl/`: CLI tool for start/pause/cancel
- `ClippyTyper/Preferences/`: Defaults and keys
- `Tests/*`: Unit tests (core + app support)
- `xcode/`: XcodeGen config, app Info.plist, and UI test stub
- `AGENTS.md`: Contributor guide; `implementationplan.md`: living plan

## Contributing
See `AGENTS.md` for coding standards, build/test commands, and workflow. Track progress in `implementationplan.md`.

## License
GPL-3.0-only. See `LICENSE` for details.
