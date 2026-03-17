import XCTest
@testable import IsClaude2xMenuBar

final class StatusServiceTests: XCTestCase {
	func testParseKnownStateParsesYes() throws {
		let state = try StatusService.parseKnownState(from: Data("yes".utf8))
		XCTAssertEqual(state, .yes)
	}

	func testParseKnownStateParsesNoWithWhitespace() throws {
		let state = try StatusService.parseKnownState(from: Data("  no \n".utf8))
		XCTAssertEqual(state, .no)
	}

	func testParseKnownStateRejectsUnexpectedPayload() {
		XCTAssertThrowsError(try StatusService.parseKnownState(from: Data("maybe".utf8))) { error in
			XCTAssertEqual(error as? StatusServiceError, .invalidPayload("maybe"))
		}
	}
}
