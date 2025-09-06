import AppKit

@main
final class HelperMain: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Typical login item helper would ping the main app, then exit.
        // For now, do nothing and quit; this stub allows SMAppService to register.
        NSApp.terminate(nil)
    }
}

