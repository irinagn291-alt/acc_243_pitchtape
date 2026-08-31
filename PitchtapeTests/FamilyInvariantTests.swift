import XCTest
@testable import Pitchtape

/// Family invariant: Clock = accumulated + now − runStartedAt (no tick drift).
/// One-tap Goal/Foul/card/Sub. Undo last. PDF after.
final class FamilyInvariantTests: XCTestCase {
    func test_clockEqualsAccumulatedPlusNowMinusRunStartedAt() {
        let runStartedAt = Date(timeIntervalSince1970: 1_000)
        let now = Date(timeIntervalSince1970: 1_045)
        let clock = TapeClock.elapsed(accumulated: 12, runStartedAt: runStartedAt, now: now)
        XCTAssertEqual(clock, 57, accuracy: 1e-12)
        XCTAssertEqual(
            TapeClock.elapsed(accumulated: 40, runStartedAt: nil, now: now),
            40,
            accuracy: 1e-12
        )
    }

    func test_oneTapGoalFoulCardSubWritesCallOnOpenPeriod() throws {
        let now = Date(timeIntervalSince1970: 2_000)
        var tape = try OpenPeriod.opening(
            home: "North",
            away: "South",
            sport: .pitch,
            fixtureDay: now,
            now: now
        )
        tape = try WhistleSplit.commit(.goal, side: .home, hand: nil, onto: tape, now: now.addingTimeInterval(8))
        tape = try WhistleSplit.commit(.foul, side: .away, hand: nil, onto: tape, now: now.addingTimeInterval(20))
        tape = try WhistleSplit.commit(.card, side: .away, hand: nil, onto: tape, now: now.addingTimeInterval(21))
        tape = try WhistleSplit.commit(.sub, side: .home, hand: nil, onto: tape, now: now.addingTimeInterval(40))
        XCTAssertEqual(tape.calls.map(\.kind), [.goal, .foul, .card, .sub])
        XCTAssertEqual(tape.calls[0].clockAt, 8, accuracy: 1e-12)
        let board = TapeFold.board(tape, now: now.addingTimeInterval(40))
        XCTAssertEqual(board.homeGoals, 1)
        XCTAssertEqual(board.awayGoals, 0)
        XCTAssertEqual(board.callCount, 4)
    }

    func test_undoPeelsLastCallOnOpenPeriodOnly() throws {
        let now = Date(timeIntervalSince1970: 3_000)
        var tape = try OpenPeriod.opening(
            home: "North",
            away: "South",
            sport: .pitch,
            fixtureDay: now,
            now: now
        )
        tape = try WhistleSplit.commit(.goal, side: .home, hand: nil, onto: tape, now: now.addingTimeInterval(5))
        tape = try WhistleSplit.commit(.foul, side: .home, hand: nil, onto: tape, now: now.addingTimeInterval(9))
        tape = try WhistleSplit.undo(tape)
        XCTAssertEqual(tape.calls.map(\.kind), [.goal])
        let pair = try WhistleSplit.parkTape(tape, at: now.addingTimeInterval(12))
        XCTAssertThrowsError(try WhistleSplit.undo(pair.sealed)) { error in
            XCTAssertEqual(error as? WhistleFault, .tapeParked)
        }
        XCTAssertEqual(pair.sealed.calls.count, 1)
    }

    func test_parkedTapesExportPDFAfterWhistle() throws {
        let now = Date(timeIntervalSince1970: 4_000)
        var tape = try OpenPeriod.opening(
            home: "North",
            away: "South",
            sport: .pitch,
            fixtureDay: now,
            now: now
        )
        tape = try WhistleSplit.commit(.goal, side: .away, hand: nil, onto: tape, now: now.addingTimeInterval(15))
        let pair = try WhistleSplit.parkTape(tape, at: now.addingTimeInterval(45))
        let data = ParkedReelPDF.render([pair.sealed, pair.next])
        XCTAssertFalse(data.isEmpty)
        let header = Data(data.prefix(5))
        XCTAssertEqual(String(data: header, encoding: .ascii), "%PDF-")
    }
}
