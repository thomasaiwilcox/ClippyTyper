import Foundation
import ApplicationServices
import Carbon

final class KeyboardEventMonitor {
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var onPauseToggle: (() -> Void)?
    var onCancel: (() -> Void)?

    private var lastEscapeTime: CFAbsoluteTime = 0
    private var doubleTapWindow: CFAbsoluteTime

    init(doubleTapWindow: CFAbsoluteTime) {
        self.doubleTapWindow = doubleTapWindow
    }

    func start() {
        guard tap == nil else { return }
        let mask = (1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard type == .keyDown, let refcon else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<KeyboardEventMonitor>.fromOpaque(refcon).takeUnretainedValue()

            let keycode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags

            // Recognize ctrl+opt+cmd+esc as cancel
            let wantCancelCombo = flags.contains(.maskControl) && flags.contains(.maskAlternate) && flags.contains(.maskCommand) && keycode == kVK_Escape
            if wantCancelCombo {
                monitor.onCancel?()
                return Unmanaged.passUnretained(event)
            }

            // Double-press ESC as emergency cancel
            if keycode == kVK_Escape {
                let now = CFAbsoluteTimeGetCurrent()
                if now - monitor.lastEscapeTime <= monitor.doubleTapWindow {
                    monitor.onCancel?()
                }
                monitor.lastEscapeTime = now
                return Unmanaged.passUnretained(event)
            }

            return Unmanaged.passUnretained(event)
        }

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(mask), callback: callback, userInfo: refcon) else {
            NSLog("KeyboardEventMonitor: failed to create event tap (Input Monitoring may be required)")
            return
        }
        self.tap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            runLoopSource = nil
        }
        if let tap = tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            self.tap = nil
        }
    }

    func setDoubleTapWindow(_ seconds: CFAbsoluteTime) { self.doubleTapWindow = max(0.1, seconds) }

    deinit { stop() }
}
