import Foundation

/// Role: Clock. Elapsed time is a fold, never a stored tick. Display type is DIN Alternate.
enum TapeClock {
    /// Clock = accumulated + now − runStartedAt. A nil origin means the tape is still.
    static func elapsed(
        accumulated: TimeInterval,
        runStartedAt: Date?,
        now: Date
    ) -> TimeInterval {
        guard let runStartedAt else { return accumulated }
        return accumulated + now.timeIntervalSince(runStartedAt)
    }

    static func display(_ seconds: TimeInterval) -> String {
        let whole = max(0, seconds.rounded(.down))
        let minutes = Int(whole) / 60
        let remainder = Int(whole) % 60
        return "\(wholeNumber(minutes, digits: 2)):\(wholeNumber(remainder, digits: 2))"
    }

    static func wholeNumber(_ value: Int, digits: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .none
        formatter.minimumIntegerDigits = digits
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
