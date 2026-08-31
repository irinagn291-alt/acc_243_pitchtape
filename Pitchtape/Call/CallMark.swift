import Foundation

/// Role: Call. One-tap kinds that land on the open tape. Event in this lexicon.
enum CallKind: String, Sendable, Equatable, CaseIterable {
    case goal
    case foul
    case card
    case sub
}

enum TapeSide: String, Sendable, Equatable, CaseIterable {
    case home
    case away
}

/// Role: Call. A written mark. clockAt is the formula snapshot at the tap, not a ticking field.
struct CallMark: Sendable, Equatable, Identifiable {
    var id: UUID
    var kind: CallKind
    var clockAt: TimeInterval
    var side: TapeSide
    var takeOrder: Int
    var hand: SheetHand?

    static func tap(
        _ kind: CallKind,
        side: TapeSide,
        hand: SheetHand?,
        clockAt: TimeInterval,
        takeOrder: Int,
        id: UUID = UUID()
    ) -> CallMark {
        CallMark(
            id: id,
            kind: kind,
            clockAt: clockAt,
            side: side,
            takeOrder: takeOrder,
            hand: hand
        )
    }
}
