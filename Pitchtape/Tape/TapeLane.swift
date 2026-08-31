import Foundation

/// Role: Tape. ReviewScreen today stays on Console. log opens Insights. goals opens Settings.
enum TapeLane: String, Equatable, Sendable {
    case today
    case log
    case goals
}

/// Role: Tape. Reads ProcessInfo arguments once after onboarding. Does not construct a View.
struct TapeLaneReader: Sendable, Equatable {
    private(set) var consumed: Bool

    init(consumed: Bool = false) {
        self.consumed = consumed
    }

    mutating func take(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        onboarded: Bool
    ) -> TapeLane? {
        guard onboarded, !consumed else { return nil }
        consumed = true
        guard let flag = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let value = arguments.index(after: flag)
        guard arguments.indices.contains(value) else { return nil }
        return TapeLane(rawValue: arguments[value])
    }
}

/// Role: Tape. Drawer destinations. The ON-AIR board stays mounted underneath.
enum BoothScene: Equatable, Sendable {
    case board
    case rack
    case reels
    case card
    case split
}
