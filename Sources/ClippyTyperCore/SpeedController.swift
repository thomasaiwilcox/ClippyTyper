import Foundation

public enum SpeedController {
    /// Returns per-character delay (seconds) for a given cps.
    /// cps <= 0 means no delay (best-effort immediate dispatch).
    public static func interval(for cps: Double) -> TimeInterval {
        guard cps > 0 else { return 0 }
        return 1.0 / cps
    }
}

