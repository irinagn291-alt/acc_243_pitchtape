import Foundation
import SwiftData

/// Role: Tape. @ModelActor seam. Maps Period/Call to Sendable structs. UI never sees @Model.
@ModelActor
actor TapeBooth {
    func loadFixtures() async throws -> [FixtureMatch] {
        try Task.checkCancellation()
        let rows = try modelContext.fetch(
            FetchDescriptor<PeriodRecord>(
                sortBy: [
                    SortDescriptor(\.fixtureDay),
                    SortDescriptor(\.periodIndex),
                    SortDescriptor(\.id),
                ]
            )
        )
        var groups: [UUID: [OpenPeriod]] = [:]
        var order: [UUID] = []
        for row in rows {
            let snapshot = try row.snapshot()
            if groups[snapshot.fixtureID] == nil {
                order.append(snapshot.fixtureID)
                groups[snapshot.fixtureID] = []
            }
            groups[snapshot.fixtureID]?.append(snapshot)
        }
        return order.compactMap { fixtureID in
            guard let periods = groups[fixtureID], let first = periods.first else { return nil }
            return FixtureMatch(
                id: fixtureID,
                homeName: first.homeName,
                awayName: first.awayName,
                kickoffDay: first.fixtureDay,
                sport: first.sport,
                periods: periods
            )
        }
    }

    func loadPeriod(id: UUID) async throws -> OpenPeriod {
        try Task.checkCancellation()
        return try row(id).snapshot()
    }

    func startFixture(
        home: String,
        away: String,
        sport: SportPattern,
        at now: Date,
        calendar: Calendar = .current
    ) async throws -> OpenPeriod {
        try Task.checkCancellation()
        let opened = try OpenPeriod.opening(
            home: home,
            away: away,
            sport: sport,
            fixtureDay: now,
            now: now,
            calendar: calendar
        )
        modelContext.insert(PeriodRecord(snapshot: opened))
        try persist()
        return opened
    }

    func commit(
        _ kind: CallKind,
        side: TapeSide,
        hand: SheetHand?,
        at now: Date,
        on periodID: UUID
    ) async throws -> OpenPeriod {
        try Task.checkCancellation()
        let record = try row(periodID)
        let next = try WhistleSplit.commit(kind, side: side, hand: hand, onto: record.snapshot(), now: now)
        guard let added = next.calls.max(by: { $0.takeOrder < $1.takeOrder }) else {
            throw WhistleFault.noOpenTape
        }
        let child = CallRecord(snapshot: added, period: record)
        modelContext.insert(child)
        try persist()
        return try record.snapshot()
    }

    func undo(on periodID: UUID) async throws -> OpenPeriod {
        try Task.checkCancellation()
        let record = try row(periodID)
        let next = try WhistleSplit.undo(record.snapshot())
        let remaining = Set(next.calls.map(\.id))
        for child in record.calls where !remaining.contains(child.id) {
            modelContext.delete(child)
        }
        try persist()
        return try record.snapshot()
    }

    func parkTape(on periodID: UUID, at now: Date) async throws -> (sealed: OpenPeriod, next: OpenPeriod) {
        try Task.checkCancellation()
        let record = try row(periodID)
        let pair = try WhistleSplit.parkTape(record.snapshot(), at: now)
        record.adopt(pair.sealed)
        modelContext.insert(PeriodRecord(snapshot: pair.next))
        try persist()
        return pair
    }

    func resetAllData() async throws {
        try Task.checkCancellation()
        let periods = try modelContext.fetch(FetchDescriptor<PeriodRecord>())
        let calls = try modelContext.fetch(FetchDescriptor<CallRecord>())
        for call in calls {
            modelContext.delete(call)
        }
        for period in periods {
            modelContext.delete(period)
        }
        try persist()
    }

    private func row(_ id: UUID) throws -> PeriodRecord {
        let target = id
        let found = try modelContext.fetch(
            FetchDescriptor<PeriodRecord>(predicate: #Predicate { $0.id == target })
        )
        guard let record = found.first else { throw TapeFault.missingPeriod }
        return record
    }

    private func persist() throws {
        do {
            try modelContext.save()
        } catch {
            throw TapeFault.saveFailed
        }
    }
}
