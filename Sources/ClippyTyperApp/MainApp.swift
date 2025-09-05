import AppKit

@main
final class MainApp: NSObject, NSApplicationDelegate {
    private let appDelegate = AppDelegate()

    func applicationDidFinishLaunching(_ notification: Notification) {
        appDelegate.applicationDidFinishLaunching(notification)
    }

    static func main() {
        let app = NSApplication.shared
        let delegate = MainApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

