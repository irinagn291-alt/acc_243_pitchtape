import XCTest
@testable import Pitchtape

final class TapeLaneTests: XCTestCase {
    func test_readsOnceAfterOnboarding() {
        var reader = TapeLaneReader()
        XCTAssertNil(reader.take(arguments: ["-ReviewScreen", "log"], onboarded: false))
        XCTAssertFalse(reader.consumed)

        let first = reader.take(arguments: ["app", "-ReviewScreen", "log"], onboarded: true)
        XCTAssertEqual(first, .log)
        XCTAssertTrue(reader.consumed)
        XCTAssertNil(reader.take(arguments: ["-ReviewScreen", "goals"], onboarded: true))
    }

    func test_unknownKeyIsIgnored() {
        var reader = TapeLaneReader()
        XCTAssertNil(reader.take(arguments: ["-ReviewScreen", "aura"], onboarded: true))
        XCTAssertTrue(reader.consumed)
    }

    func test_todayLogGoalsKeys() {
        var today = TapeLaneReader()
        XCTAssertEqual(today.take(arguments: ["-ReviewScreen", "today"], onboarded: true), .today)
        var goals = TapeLaneReader()
        XCTAssertEqual(goals.take(arguments: ["-ReviewScreen", "goals"], onboarded: true), .goals)
        var log = TapeLaneReader()
        XCTAssertEqual(log.take(arguments: ["-ReviewScreen", "log"], onboarded: true), .log)
    }
}
