import XCTest
@testable import Pitchtape

final class PitchtapeTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: PitchtapeApp.self), "PitchtapeApp")
    }
}
