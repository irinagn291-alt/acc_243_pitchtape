import XCTest
import SwiftData
@testable import Pitchtape

@MainActor
final class BoothDeskTests: XCTestCase {
    func test_applyReviewOpensThreeDifferentScenes() async throws {
        let desk = try makeDesk()
        desk.onboarded = true
        desk.applyReview(arguments: ["-ReviewScreen", "today"])
        XCTAssertEqual(desk.scene, .board)
        XCTAssertEqual(desk.reviewLane, .today)

        let log = try makeDesk()
        log.onboarded = true
        log.applyReview(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(log.scene, .reels)
        XCTAssertEqual(log.reviewLane, .log)

        let goals = try makeDesk()
        goals.onboarded = true
        goals.applyReview(arguments: ["-ReviewScreen", "goals"])
        XCTAssertEqual(goals.scene, .card)
        XCTAssertEqual(goals.reviewLane, .goals)
    }

    func test_reviewIsIgnoredBeforeOnboardingAndThenReadOnce() async throws {
        let desk = try makeDesk()
        desk.onboarded = false
        desk.applyReview(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(desk.scene, .board)
        XCTAssertNil(desk.reviewLane)

        desk.onboarded = true
        desk.applyReview(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(desk.scene, .reels)
        desk.applyReview(arguments: ["-ReviewScreen", "goals"])
        XCTAssertEqual(desk.scene, .reels)
    }

    func test_commitUndoAndWhistleThroughDeskWithoutView() async throws {
        let desk = try makeDesk()
        let now = Date(timeIntervalSince1970: 20_000)
        await desk.startFixture(home: "North", away: "South", sport: .pitch, at: now)
        XCTAssertEqual(desk.openPeriod?.phase, .running)
        XCTAssertTrue(desk.canTap)

        await desk.tap(.goal, at: now.addingTimeInterval(8))
        XCTAssertEqual(desk.openPeriod?.calls.map(\.kind), [.goal])
        XCTAssertEqual(desk.openPeriod?.calls.first?.clockAt ?? -1, 8, accuracy: 1e-12)

        await desk.undoLast()
        XCTAssertTrue(desk.openPeriod?.calls.isEmpty == true)

        await desk.tap(.foul, at: now.addingTimeInterval(12))
        await desk.blowWhistle(at: now.addingTimeInterval(20))
        XCTAssertEqual(desk.openPeriod?.phase, .running)
        XCTAssertEqual(desk.openPeriod?.periodIndex, 2)
        XCTAssertTrue(desk.openPeriod?.calls.isEmpty == true)
        XCTAssertEqual(desk.parkedTapes.count, 1)
        XCTAssertEqual(desk.parkedTapes.first?.phase, .parked)
    }

    func test_seedLeavesGoalLiveAndFillsParkedTapes() async throws {
        let container = try openMemory()
        let booth = TapeBooth(modelContainer: container)
        try await TapeSeed.plant(using: booth, now: Date(timeIntervalSince1970: 30_000))
        let fixtures = try await booth.loadFixtures()
        XCTAssertGreaterThanOrEqual(fixtures.count, 2)
        XCTAssertGreaterThanOrEqual(fixtures.flatMap(\.parkedTapes).count, 3)
        XCTAssertTrue(fixtures.contains { $0.openTape != nil })
        let live = try XCTUnwrap(fixtures.reversed().first { $0.openTape != nil }?.openTape)
        XCTAssertEqual(live.phase, .running)
        XCTAssertEqual(live.homeName, "Northside")
        XCTAssertFalse(live.calls.isEmpty)
    }

    private func makeDesk() throws -> BoothDesk {
        let suite = "ptp.desk.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return BoothDesk(
            booth: TapeBooth(modelContainer: try openMemory()),
            prefs: TapePrefs(defaults: defaults)
        )
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
