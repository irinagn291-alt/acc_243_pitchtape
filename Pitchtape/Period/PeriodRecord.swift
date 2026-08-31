import Foundation
import SwiftData

/// Role: Period. SwiftData row. Clock and score stay off this type.
@Model
final class PeriodRecord {
    @Attribute(.unique) var id: UUID
    var fixtureID: UUID
    var phaseRaw: String
    var accumulated: Double
    var runStartedAt: Date?
    var homeName: String
    var awayName: String
    var markWhistledAt: Date?
    var markIndex: Int?
    /// Leftover Julian day number daykey is unused; fixture dates use Calendar startOfDay.
    var fixtureDay: Date
    var sportRaw: String
    var periodIndex: Int
    @Relationship(deleteRule: .cascade, inverse: \CallRecord.period)
    var calls: [CallRecord]

    init(
        id: UUID,
        fixtureID: UUID,
        phaseRaw: String,
        accumulated: Double,
        runStartedAt: Date?,
        homeName: String,
        awayName: String,
        markWhistledAt: Date?,
        markIndex: Int?,
        fixtureDay: Date,
        sportRaw: String,
        periodIndex: Int,
        calls: [CallRecord] = []
    ) {
        self.id = id
        self.fixtureID = fixtureID
        self.phaseRaw = phaseRaw
        self.accumulated = accumulated
        self.runStartedAt = runStartedAt
        self.homeName = homeName
        self.awayName = awayName
        self.markWhistledAt = markWhistledAt
        self.markIndex = markIndex
        self.fixtureDay = fixtureDay
        self.sportRaw = sportRaw
        self.periodIndex = periodIndex
        self.calls = calls
    }

    convenience init(snapshot: OpenPeriod) {
        self.init(
            id: snapshot.id,
            fixtureID: snapshot.fixtureID,
            phaseRaw: snapshot.phase.rawValue,
            accumulated: snapshot.accumulated,
            runStartedAt: snapshot.runStartedAt,
            homeName: snapshot.homeName,
            awayName: snapshot.awayName,
            markWhistledAt: snapshot.mark?.whistledAt,
            markIndex: snapshot.mark?.periodIndex,
            fixtureDay: snapshot.fixtureDay,
            sportRaw: snapshot.sport.rawValue,
            periodIndex: snapshot.periodIndex
        )
    }

    func adopt(_ snapshot: OpenPeriod) {
        phaseRaw = snapshot.phase.rawValue
        accumulated = snapshot.accumulated
        runStartedAt = snapshot.runStartedAt
        homeName = snapshot.homeName
        awayName = snapshot.awayName
        markWhistledAt = snapshot.mark?.whistledAt
        markIndex = snapshot.mark?.periodIndex
        fixtureDay = snapshot.fixtureDay
        sportRaw = snapshot.sport.rawValue
        periodIndex = snapshot.periodIndex
    }

    func snapshot() throws -> OpenPeriod {
        guard let phase = PeriodPhase(rawValue: phaseRaw) else { throw TapeFault.bentRow }
        guard let sport = SportPattern(rawValue: sportRaw) else { throw TapeFault.bentRow }
        let mark: PeriodMark?
        if let markWhistledAt, let markIndex {
            mark = PeriodMark(whistledAt: markWhistledAt, periodIndex: markIndex)
        } else {
            mark = nil
        }
        let marks = try calls.map { try $0.snapshot() }.sorted { lhs, rhs in
            if lhs.takeOrder != rhs.takeOrder { return lhs.takeOrder < rhs.takeOrder }
            return lhs.id.uuidString < rhs.id.uuidString
        }
        return OpenPeriod(
            id: id,
            fixtureID: fixtureID,
            phase: phase,
            accumulated: accumulated,
            runStartedAt: runStartedAt,
            homeName: homeName,
            awayName: awayName,
            mark: mark,
            fixtureDay: fixtureDay,
            sport: sport,
            periodIndex: periodIndex,
            calls: marks
        )
    }
}
