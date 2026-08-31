import XCTest
import SwiftData
@testable import Pitchtape

final class TapeBoothTests: XCTestCase {
    func test_roundTripReloadPreservesPeriodAndCall() async throws {
        let container = try openMemory()
        let writer = TapeBooth(modelContainer: container)
        let now = Date(timeIntervalSince1970: 8_000)
        let opened = try await writer.startFixture(home: "North", away: "South", sport: .pitch, at: now)
        let written = try await writer.commit(
            .goal,
            side: .home,
            hand: try SheetHand(name: "Kim", shirt: 7),
            at: now.addingTimeInterval(14),
            on: opened.id
        )

        let reader = TapeBooth(modelContainer: container)
        let loaded = try await reader.loadPeriod(id: opened.id)
        XCTAssertEqual(loaded.id, opened.id)
        XCTAssertEqual(loaded.homeName, "North")
        XCTAssertEqual(loaded.awayName, "South")
        XCTAssertEqual(loaded.phase, .running)
        XCTAssertEqual(loaded.calls.count, 1)
        XCTAssertEqual(loaded.calls[0].kind, .goal)
        XCTAssertEqual(loaded.calls[0].clockAt, 14, accuracy: 1e-12)
        XCTAssertEqual(loaded.calls[0].hand?.name, "Kim")
        XCTAssertEqual(written.calls[0].id, loaded.calls[0].id)
        XCTAssertEqual(loaded.fixtureDay, Calendar.current.startOfDay(for: now))
    }

    func test_resetAllDataWipesPeriodAndCall() async throws {
        let booth = TapeBooth(modelContainer: try openMemory())
        let now = Date(timeIntervalSince1970: 9_000)
        let opened = try await booth.startFixture(home: "North", away: "South", sport: .pitch, at: now)
        _ = try await booth.commit(.foul, side: .away, hand: nil, at: now.addingTimeInterval(4), on: opened.id)
        try await booth.resetAllData()
        let fixtures = try await booth.loadFixtures()
        XCTAssertTrue(fixtures.isEmpty)
    }

    func test_parkTapePersistsSealedAndNext() async throws {
        let booth = TapeBooth(modelContainer: try openMemory())
        let now = Date(timeIntervalSince1970: 10_000)
        let opened = try await booth.startFixture(home: "North", away: "South", sport: .pitch, at: now)
        _ = try await booth.commit(.goal, side: .away, hand: nil, at: now.addingTimeInterval(6), on: opened.id)
        let pair = try await booth.parkTape(on: opened.id, at: now.addingTimeInterval(20))
        let fixtures = try await booth.loadFixtures()
        XCTAssertEqual(fixtures.count, 1)
        XCTAssertEqual(fixtures[0].periods.count, 2)
        XCTAssertEqual(fixtures[0].parkedTapes.count, 1)
        XCTAssertEqual(fixtures[0].openTape?.id, pair.next.id)
        XCTAssertEqual(pair.sealed.phase, .parked)
        XCTAssertEqual(pair.sealed.calls.count, 1)
    }

    func test_undoDoesNotTouchParkedCalls() async throws {
        let booth = TapeBooth(modelContainer: try openMemory())
        let now = Date(timeIntervalSince1970: 11_000)
        let opened = try await booth.startFixture(home: "North", away: "South", sport: .pitch, at: now)
        _ = try await booth.commit(.goal, side: .home, hand: nil, at: now.addingTimeInterval(2), on: opened.id)
        let pair = try await booth.parkTape(on: opened.id, at: now.addingTimeInterval(9))
        do {
            _ = try await booth.undo(on: pair.sealed.id)
            XCTFail("expected tapeParked")
        } catch {
            XCTAssertEqual(error as? WhistleFault, .tapeParked)
        }
        let sealed = try await booth.loadPeriod(id: pair.sealed.id)
        XCTAssertEqual(sealed.calls.count, 1)
        _ = try await booth.commit(.sub, side: .away, hand: nil, at: now.addingTimeInterval(12), on: pair.next.id)
        let peeled = try await booth.undo(on: pair.next.id)
        XCTAssertTrue(peeled.calls.isEmpty)
        XCTAssertEqual(sealed.calls.count, 1)
    }

    private func openMemory() throws -> ModelContainer {
        switch TapeChest.memory() {
        case .success(let container):
            return container
        case .failure(let error):
            throw error
        }
    }
}
