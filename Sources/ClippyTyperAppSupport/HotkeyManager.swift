import Foundation
import AppKit
import Carbon

public final class HotkeyManager {
    public typealias Callback = () -> Void

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var handlerUPP: EventHandlerUPP?
    private var callback: Callback?
    private var registeredID: EventHotKeyID?
    private static var nextID: UInt32 = 1

    public init() {}

    deinit { unregister() }

    @discardableResult
    public func register(hotkeyString: String, callback: @escaping Callback) -> Bool {
        unregister()
        self.callback = callback

        guard let parsed = Self.parse(hotkeyString: hotkeyString) else {
            NSLog("Hotkey parse failed for string: \(hotkeyString)")
            return false
        }

        var myID = EventHotKeyID(signature: OSType(UInt32(truncatingIfNeeded: 0x434C5054)), id: Self.nextAvailableID()) // 'CLPT'
        let status = RegisterEventHotKey(parsed.keyCode, parsed.modifiers, myID, GetEventDispatcherTarget(), 0, &hotKeyRef)
        if status != noErr {
            NSLog("RegisterEventHotKey failed: \(status)")
            return false
        }
        self.registeredID = myID

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let handler: EventHandlerUPP = { (callRef, eventRef, userData) -> OSStatus in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            // Extract the hotkey ID from the event and compare
            var eventHotKeyID = EventHotKeyID()
            let status = GetEventParameter(eventRef, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &eventHotKeyID)
            if status != noErr {
                return OSStatus(eventNotHandledErr)
            }
            if let reg = manager.registeredID, reg.id == eventHotKeyID.id, reg.signature == eventHotKeyID.signature {
                manager.callback?()
                return noErr
            } else {
                return OSStatus(eventNotHandledErr)
            }
        }
        self.handlerUPP = handler // keep alive
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let installStatus = InstallEventHandler(GetEventDispatcherTarget(), handler, 1, &eventSpec, userData, &eventHandler)
        if installStatus != noErr {
            NSLog("InstallEventHandler failed: \(installStatus)")
            return false
        }
        return true
    }

    public func unregister() {
        if let hk = hotKeyRef {
            UnregisterEventHotKey(hk)
            hotKeyRef = nil
        }
        if let eh = eventHandler {
            RemoveEventHandler(eh)
            eventHandler = nil
        }
        handlerUPP = nil
        callback = nil
        registeredID = nil
    }

    public struct ParsedHotkey {
        public let keyCode: UInt32
        public let modifiers: UInt32
    }

    public static func parse(hotkeyString: String) -> ParsedHotkey? {
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
                "8": kVK_ANSI_8, "9": kVK_ANSI_9,
                "-": kVK_ANSI_Minus, "=": kVK_ANSI_Equal,
                "[": kVK_ANSI_LeftBracket, "]": kVK_ANSI_RightBracket,
                "\\": kVK_ANSI_Backslash,
                ";": kVK_ANSI_Semicolon, "'": kVK_ANSI_Quote,
                ",": kVK_ANSI_Comma, ".": kVK_ANSI_Period, "/": kVK_ANSI_Slash,
                "`": kVK_ANSI_Grave
            ]
            return map[ch]
        }
        // Named keys
        switch key {
        case "esc", "escape": return kVK_Escape
        case "backspace", "delete": return kVK_Delete
        case "forwarddelete", "del": return kVK_ForwardDelete
        case "return", "enter": return kVK_Return
        case "tab": return kVK_Tab
        case "space", "spacebar": return kVK_Space
        case "left": return kVK_LeftArrow
        case "right": return kVK_RightArrow
        case "up": return kVK_UpArrow
        case "down": return kVK_DownArrow
        case "home": return kVK_Home
        case "end": return kVK_End
        case "pageup": return kVK_PageUp
        case "pagedown": return kVK_PageDown
        case let f where f.hasPrefix("f"):
            if let n = Int(f.dropFirst()), (1...19).contains(n) {
                return kVK_F1 + (n - 1)
            } else {
                break
            }
        default: break
        }
        return nil
    }
}

extension HotkeyManager {
    private static func nextAvailableID() -> UInt32 {
        // Simple increment with wraparound safeguard
        let id = nextID
        nextID &+= 1
        if nextID == 0 { nextID = 1 }
        return id
    }
}
