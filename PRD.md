Product Requirements Document (PRD)

Product Name: ClippyTyper
Platform: macOS (Primary target: macOS Sonoma)
Version: 1.0

⸻

1. Overview

ClippyTyper is a lightweight macOS utility designed to take the text currently stored in the system clipboard and simulate typing it into the currently active application. The app provides a seamless way to transfer clipboard contents into any text input field by emulating keystrokes rather than pasting.

⸻

2. Goals and Objectives
	•	Provide a simple, reliable way to type out clipboard contents character by character into the active application.
	•	Operate unobtrusively in the background with minimal resource usage.
	•	Ensure user control through configurable shortcuts and preferences.
	•	Maintain compatibility with macOS accessibility and input APIs.

⸻

3. Key Features

3.1 Core Functionality
	•	Capture clipboard text on invocation.
	•	Simulate typing the clipboard text into the currently active window.
	•	Support multi-line text input.
	•	Handle common text encodings (UTF-8, emoji, special characters).

3.2 User Controls
	•	Keyboard Shortcut Trigger: Customisable global hotkey to trigger typing.
	•	Menu Bar Icon: Minimal status bar menu for preferences and quick access.
	•	Preferences Panel:
	•	Set or change global hotkey.
	•	Adjust typing speed (characters per second).
	•	Enable/disable app launch at login.

3.3 Advanced Features (v1.0 or later minor releases)
	•	Pause/resume typing shortcut.
	•	Cancel typing shortcut.
	•	Option for “instant paste” (direct insert) as a fallback.
	•	Configurable per-app exceptions (apps where typing should not occur).

⸻

4. Non-Goals
	•	Rich formatting handling (ClippyTyper will only process plain text).
	•	Clipboard history management.
	•	Cross-device clipboard syncing.

⸻

5. Technical Requirements

5.1 Platform Support
	•	macOS Sonoma (primary).
	•	Backward compatibility with Ventura and Monterey (where possible).

5.2 APIs and Frameworks
	•	macOS Accessibility API (AXUIElement) for keystroke simulation.
	•	macOS Pasteboard API for clipboard access.
	•	macOS AppKit for menu bar and preferences UI.

5.3 Security and Permissions
	•	Accessibility permissions must be granted by the user for keystroke simulation.
	•	No network access required.
	•	No persistent storage of clipboard data beyond the typing session.

⸻

6. User Experience

6.1 Typical Flow
	1.	User copies text to clipboard.
	2.	User switches to target application.
	3.	User presses the configured global shortcut.
	4.	ClippyTyper begins typing the clipboard text into the active window.
	5.	User can cancel or pause typing with shortcuts if needed.

6.2 UI/UX Design Principles
	•	Minimalist design, small menu bar presence.
	•	Focus on efficiency and low cognitive load.
	•	Preferences dialog with a simple macOS-native look.

⸻

7. Performance Considerations
	•	Typing speed configurable, with defaults that balance speed and reliability.
	•	Efficient background service, consuming negligible CPU/memory when idle.
	•	Graceful handling of large clipboard content (e.g., >10k characters).

⸻

8. Risks and Dependencies
	•	Reliance on Accessibility APIs requires user permission setup.
	•	Certain system-protected apps may not allow simulated input.
	•	International keyboard layouts may require extra testing to ensure correctness.

⸻

9. Success Metrics
	•	Successful typing of clipboard content across a wide range of macOS applications.
	•	User satisfaction with reliability and ease of use.
	•	Low crash rate and minimal reported bugs.

⸻

10. Future Enhancements
	•	Multi-language keyboard support.
	•	Optional per-character delays for human-like typing simulation.
	•	Scripting/API support for automation workflows.
