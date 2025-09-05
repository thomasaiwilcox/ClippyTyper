import Foundation

public enum KeystrokeError: Error, Equatable {
    case sendFailed(String)
}

/// Abstraction over keystroke dispatch.
/// The app layer will provide an AX-based implementation.
public protocol KeystrokeSender {
    func send(character: Character) throws
}

