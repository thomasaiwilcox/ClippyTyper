import Foundation
import AppKit
import Carbon

final class HotkeyManager {
    typealias Callback = () -> Void

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: Callback?

    deinit { unregister() }

    func register(hotkeyString: String, callback: @escaping Callback) {
        unregister()
        self.callback = callback

        guard let parsed = Self.parse(hotkeyString: hotkeyString) else {
            NSLog("Hotkey parse failed for string: \(hotkeyString)")
            return
        }

        let hotKeyID = EventHotKeyID(signature: OSType(UInt32(truncatingIfNeeded: 0x434C5054)), id: UInt32(1)) // 'CLPT'
        let status = RegisterEventHotKey(parsed.keyCode, parsed.modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
        if status != noErr {
            NSLog("RegisterEventHotKey failed: \(status)")
            return
        }

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let handler: EventHandlerUPP = { (_, _, userData) -> OSStatus in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.callback?()
            return noErr
        }
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let installStatus = InstallEventHandler(GetEventDispatcherTarget(), handler, 1, &eventSpec, userData, &eventHandler)
        if installStatus != noErr {
            NSLog("InstallEventHandler failed: \(installStatus)")
        }
    }

    func unregister() {
        if let hk = hotKeyRef {
            UnregisterEventHotKey(hk)
            hotKeyRef = nil
        }
        if let eh = eventHandler {
            RemoveEventHandler(eh)
            eventHandler = nil
        }
        callback = nil
    }

    struct ParsedHotkey {
        let keyCode: UInt32
        let modifiers: UInt32
    }

    static func parse(hotkeyString: String) -> ParsedHotkey? {
        let parts = hotkeyString.lowercased().split(separator: "+").map { String($0) }
        guard !parts.isEmpty else { return nil }

        var mods: UInt32 = 0
        var keyPart: String?

        for part in parts {
            switch part {
            case "cmd", "command": mods |= UInt32(cmdKey)
            case "opt", "option", "alt": mods |= UInt32(optionKey)
            case "ctrl", "control": mods |= UInt32(controlKey)
            case "shift": mods |= UInt32(shiftKey)
            default: keyPart = part
            }
        }

        guard let keyPart else { return nil }
        guard let code = keyCode(for: keyPart) else { return nil }
        return ParsedHotkey(keyCode: UInt32(code), modifiers: mods)
    }

    private static func keyCode(for key: String) -> Int? {
        if key.count == 1, let ch = key.first {
            let map: [Character: Int] = [
                "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D,
                "e": kVK_ANSI_E, "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H,
                "i": kVK_ANSI_I, "j": kVK_ANSI_J, "k": kVK_ANSI_K, "l": kVK_ANSI_L,
                "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O, "p": kVK_ANSI_P,
                "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
                "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X,
                "y": kVK_ANSI_Y, "z": kVK_ANSI_Z,
                "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3,
                "4": kVK_ANSI_4, "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7,
                "8": kVK_ANSI_8, "9": kVK_ANSI_9
            ]
            return map[ch]
        }
        // Named keys
        switch key {
        case "esc", "escape": return kVK_Escape
        case "backspace", "delete": return kVK_Delete
        default: break
        }
        return nil
    }
}
