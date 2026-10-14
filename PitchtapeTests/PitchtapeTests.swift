import XCTest
@testable import Pitchtape

final class PitchtapeTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: PitchtapeApp.self), "PitchtapeApp")
    }

    func test_tapTargetMeetsComfortSize() {
        XCTAssertGreaterThanOrEqual(TapeBevel.tap, 44)
    }

    func test_airedCopyKeepsWordGaps() {
        let aired = TapeFace.aired("Keep a sheet on the touchline.", step: .title)
        let rendered = String(aired.characters)
        XCTAssertTrue(rendered.contains("\u{2002}"))
        XCTAssertTrue(rendered.contains("Keep"))
        XCTAssertTrue(rendered.contains("sheet"))
        XCTAssertTrue(rendered.contains("touchline"))
    }
}
