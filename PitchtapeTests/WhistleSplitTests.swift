import XCTest
@testable import Pitchtape

final class WhistleSplitTests: XCTestCase {
    func test_emptyPopulatedAndInvalidPrimaryVerb() throws {
        let now = Date(timeIntervalSince1970: 5_000)
        XCTAssertThrowsError(
            try OpenPeriod.opening(home: "  ", away: "South", sport: .pitch, fixtureDay: now, now: now)
        ) { error in
            XCTAssertEqual(error as? WhistleFault, .blankSide)
        }

        var tape = try OpenPeriod.opening(
            home: "North",
            away: "South",
            sport: .pitch,
            fixtureDay: now,
            now: now
        )
        XCTAssertTrue(tape.calls.isEmpty)
        XCTAssertEqual(tape.phase, .running)

        tape = try WhistleSplit.commit(.goal, side: .home, hand: nil, onto: tape, now: now.addingTimeInterval(3))
        XCTAssertEqual(tape.calls.count, 1)
        XCTAssertEqual(TapeFold.board(tape, now: now.addingTimeInterval(3)).homeGoals, 1)

        let pair = try WhistleSplit.parkTape(tape, at: now.addingTimeInterval(10))
        XCTAssertThrowsError(
            try WhistleSplit.commit(.goal, side: .home, hand: nil, onto: pair.sealed, now: now.addingTimeInterval(11))
        ) { error in
            XCTAssertEqual(error as? WhistleFault, .tapeParked)
        }
        XCTAssertEqual(pair.next.calls.count, 0)
        XCTAssertEqual(pair.next.phase, .running)
    }

    func test_whistleParksAndOpensNextRunningTape() throws {
        let now = Date(timeIntervalSince1970: 6_000)
        var tape = try OpenPeriod.opening(
            home: "North",
            away: "South",
            sport: .ice,
            fixtureDay: now,
            now: now
        )
        tape = try WhistleSplit.commit(.goal, side: .home, hand: nil, onto: tape, now: now.addingTimeInterval(30))
        let pair = try WhistleSplit.parkTape(tape, at: now.addingTimeInterval(60))
        XCTAssertEqual(pair.sealed.phase, .parked)
        XCTAssertNil(pair.sealed.runStartedAt)
        XCTAssertEqual(pair.sealed.accumulated, 60, accuracy: 1e-12)
        XCTAssertEqual(pair.sealed.mark?.periodIndex, 1)
        XCTAssertEqual(pair.sealed.calls.count, 1)
        XCTAssertEqual(pair.next.phase, .running)
        XCTAssertEqual(pair.next.periodIndex, 2)
        XCTAssertEqual(pair.next.fixtureID, pair.sealed.fixtureID)
        XCTAssertTrue(pair.next.calls.isEmpty)
        XCTAssertEqual(pair.next.clock(at: now.addingTimeInterval(70)), 10, accuracy: 1e-12)
        XCTAssertThrowsError(try WhistleSplit.parkTape(pair.sealed, at: now.addingTimeInterval(80))) { error in
            XCTAssertEqual(error as? WhistleFault, .alreadyParked)
        }
    }

    func test_periodADTHasOnlyRunningAndParked() {
        XCTAssertEqual(PeriodPhase.allCases, [.running, .parked])
        XCTAssertEqual(PeriodPhase.allCases.count, 2)
    }

    func test_fixtureDayUsesStartOfDayNotJulian() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 8
        parts.day = 31
        parts.hour = 21
        parts.minute = 40
        let late = try XCTUnwrap(calendar.date(from: parts))
        let tape = try OpenPeriod.opening(
            home: "North",
            away: "South",
            sport: .court,
            fixtureDay: late,
            now: late,
            calendar: calendar
        )
        XCTAssertEqual(tape.fixtureDay, calendar.startOfDay(for: late))
        XCTAssertNotEqual(tape.fixtureDay, late)
    }

    func test_undoOnEmptyOpenTapeFails() throws {
        let now = Date(timeIntervalSince1970: 7_000)
        let tape = try OpenPeriod.opening(
            home: "North",
            away: "South",
            sport: .pitch,
            fixtureDay: now,
            now: now
        )
        XCTAssertThrowsError(try WhistleSplit.undo(tape)) { error in
            XCTAssertEqual(error as? WhistleFault, .tapeEmpty)
        }
    }

    func test_sheetHandRejectsBlankName() {
        XCTAssertThrowsError(try SheetHand(name: "  ", shirt: 9)) { error in
            XCTAssertEqual(error as? WhistleFault, .blankHand)
        }
    }
}
