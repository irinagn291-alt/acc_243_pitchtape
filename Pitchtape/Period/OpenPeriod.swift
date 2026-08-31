import Foundation

/// Role: Period. Closed ADT. The only cases are running and parked.
enum PeriodPhase: String, Sendable, Equatable, CaseIterable {
    case running
    case parked
}

/// Role: Period. Sendable open or sealed tape. Views never hold a second phase enum.
struct OpenPeriod: Sendable, Equatable, Identifiable {
    var id: UUID
    var fixtureID: UUID
    var phase: PeriodPhase
    var accumulated: TimeInterval
    var runStartedAt: Date?
    var homeName: String
    var awayName: String
    var mark: PeriodMark?
    var fixtureDay: Date
    var sport: SportPattern
    var periodIndex: Int
    var calls: [CallMark]

    var isRunning: Bool { phase == .running }

    func clock(at now: Date) -> TimeInterval {
        TapeClock.elapsed(accumulated: accumulated, runStartedAt: runStartedAt, now: now)
    }

    static func opening(
        home: String,
        away: String,
        sport: SportPattern,
        fixtureDay: Date,
        now: Date,
        fixtureID: UUID = UUID(),
        periodIndex: Int = 1,
        id: UUID = UUID(),
        calendar: Calendar = .current
    ) throws -> OpenPeriod {
        let homeName = home.trimmingCharacters(in: .whitespacesAndNewlines)
        let awayName = away.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !homeName.isEmpty, !awayName.isEmpty else { throw WhistleFault.blankSide }
        return OpenPeriod(
            id: id,
            fixtureID: fixtureID,
            phase: .running,
            accumulated: 0,
            runStartedAt: now,
            homeName: homeName,
            awayName: awayName,
            mark: nil,
            fixtureDay: calendar.startOfDay(for: fixtureDay),
            sport: sport,
            periodIndex: periodIndex,
            calls: []
        )
    }
}
