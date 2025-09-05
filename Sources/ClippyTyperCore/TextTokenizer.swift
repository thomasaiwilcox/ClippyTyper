import Foundation

public enum TextTokenizer {
    /// Tokenizes text into user-perceived characters.
    /// Swift's `Character` already represents extended grapheme clusters
    /// (handles emoji and composed characters).
    public static func tokenize(_ text: String) -> [Character] {
        Array(text)
    }
}

