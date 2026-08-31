import Foundation

/// Role: Tape. Local sport template. No odds and no money.
enum SportPattern: String, Sendable, Equatable, CaseIterable {
    case pitch
    case ice
    case court
}

/// Role: Tape. Player in this lexicon. Optional attribution on a Call.
struct SheetHand: Sendable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var shirt: Int

    init(id: UUID = UUID(), name: String, shirt: Int) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw WhistleFault.blankHand }
        self.id = id
        self.name = trimmed
        self.shirt = shirt
    }
}

/// Role: Tape. Match in this lexicon. A fold of Periods that share one fixture.
struct FixtureMatch: Sendable, Equatable, Identifiable {
    var id: UUID
    var homeName: String
    var awayName: String
    var kickoffDay: Date
    var sport: SportPattern
    var periods: [OpenPeriod]

    var openTape: OpenPeriod? {
        periods.first(where: \.isRunning)
    }

    var parkedTapes: [OpenPeriod] {
        periods.filter { $0.phase == .parked }
    }
}

/// Role: Tape. Score and clock are derived. They are never stored ticks.
struct LiveBoard: Sendable, Equatable {
    var clock: TimeInterval
    var homeGoals: Int
    var awayGoals: Int
    var callCount: Int
}

enum TapeFold {
    static func score(calls: [CallMark]) -> (home: Int, away: Int) {
        var home = 0
        var away = 0
        for mark in calls where mark.kind == .goal {
            switch mark.side {
            case .home: home += 1
            case .away: away += 1
            }
        }
        return (home, away)
    }

    static func board(_ period: OpenPeriod, now: Date) -> LiveBoard {
        let pair = score(calls: period.calls)
        return LiveBoard(
            clock: period.clock(at: now),
            homeGoals: pair.home,
            awayGoals: pair.away,
            callCount: period.calls.count
        )
    }

    static func fixture(_ match: FixtureMatch, now: Date) -> LiveBoard {
        let marks = match.periods.flatMap(\.calls)
        let pair = score(calls: marks)
        let clock: TimeInterval
        if let live = match.openTape {
            clock = live.clock(at: now)
        } else if let last = match.periods.max(by: { $0.periodIndex < $1.periodIndex }) {
            clock = last.accumulated
        } else {
            clock = 0
        }
        return LiveBoard(
            clock: clock,
            homeGoals: pair.home,
            awayGoals: pair.away,
            callCount: marks.count
        )
    }

    static func scoreText(_ period: OpenPeriod) -> String {
        let pair = score(calls: period.calls)
        return "\(TapeClock.wholeNumber(pair.home))–\(TapeClock.wholeNumber(pair.away))"
    }
}
