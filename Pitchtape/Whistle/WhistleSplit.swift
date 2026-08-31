import Foundation

/// Role: Whistle. Seals a running tape. Written only by parkTape.
struct PeriodMark: Sendable, Equatable {
    var whistledAt: Date
    var periodIndex: Int
}

enum WhistleFault: Error, Equatable, Sendable {
    case blankSide
    case blankHand
    case noOpenTape
    case tapeParked
    case tapeEmpty
    case alreadyParked
}

/// Role: Whistle. Views call commit, undo, and parkTape. The match is a fold over Calls.
enum WhistleSplit {
    static func commit(
        _ kind: CallKind,
        side: TapeSide,
        hand: SheetHand?,
        onto period: OpenPeriod,
        now: Date
    ) throws -> OpenPeriod {
        guard period.phase == .running else { throw WhistleFault.tapeParked }
        var next = period
        let order = (period.calls.map(\.takeOrder).max() ?? -1) + 1
        next.calls.append(
            CallMark.tap(
                kind,
                side: side,
                hand: hand,
                clockAt: period.clock(at: now),
                takeOrder: order
            )
        )
        next.calls.sort { lhs, rhs in
            if lhs.takeOrder != rhs.takeOrder { return lhs.takeOrder < rhs.takeOrder }
            return lhs.id.uuidString < rhs.id.uuidString
        }
        return next
    }

    static func undo(_ period: OpenPeriod) throws -> OpenPeriod {
        guard period.phase == .running else { throw WhistleFault.tapeParked }
        guard let last = period.calls.max(by: { $0.takeOrder < $1.takeOrder }) else {
            throw WhistleFault.tapeEmpty
        }
        var next = period
        next.calls.removeAll { $0.id == last.id }
        return next
    }

    static func parkTape(_ period: OpenPeriod, at now: Date) throws -> (sealed: OpenPeriod, next: OpenPeriod) {
        guard period.phase == .running else { throw WhistleFault.alreadyParked }
        var sealed = period
        sealed.accumulated = period.clock(at: now)
        sealed.runStartedAt = nil
        sealed.phase = .parked
        sealed.mark = PeriodMark(whistledAt: now, periodIndex: period.periodIndex)
        let next = try OpenPeriod.opening(
            home: period.homeName,
            away: period.awayName,
            sport: period.sport,
            fixtureDay: period.fixtureDay,
            now: now,
            fixtureID: period.fixtureID,
            periodIndex: period.periodIndex + 1
        )
        return (sealed, next)
    }
}
