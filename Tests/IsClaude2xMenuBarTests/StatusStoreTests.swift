import Foundation
import XCTest
@testable import IsClaude2xMenuBar

final class StatusStoreTests: XCTestCase {
	@MainActor
	func testRefreshUpdatesVisibleStateAndTimestamp() async {
		let checkedAt = makeDate(hour: 13, minute: 0, second: 2)
		let service = MockStatusService(results: [.success(FetchResult(state: .yes, checkedAt: checkedAt))])
		let store = StatusStore(service: service, nowProvider: { checkedAt }, autoStart: false)
		let fetchExpectation = expectation(description: "fetch")
		service.onFetch = { fetchExpectation.fulfill() }

		store.refreshNow()
		await fulfillment(of: [fetchExpectation], timeout: 1)

		XCTAssertEqual(store.state, .yes)
		XCTAssertEqual(store.lastCheckedAt, checkedAt)
		XCTAssertNil(store.errorMessage)
	}

	@MainActor
	func testFailedRefreshPreservesLastKnownState() async {
		let initialDate = makeDate(hour: 13, minute: 0, second: 2)
		let failedDate = makeDate(hour: 13, minute: 15, second: 2)
		let service = MockStatusService(results: [
			.success(FetchResult(state: .yes, checkedAt: initialDate)),
			.failure(MockError.network)
		])
		var currentDate = initialDate
		let store = StatusStore(service: service, nowProvider: { currentDate }, autoStart: false)
		let secondFetchExpectation = expectation(description: "second fetch")
		secondFetchExpectation.expectedFulfillmentCount = 1
		service.fetchCountHandler = { count in
			if count == 2 {
				secondFetchExpectation.fulfill()
			}
		}

		store.refreshNow()
		try? await Task.sleep(nanoseconds: 100_000_000)
		currentDate = failedDate
		store.refreshNow()
		await fulfillment(of: [secondFetchExpectation], timeout: 1)

		XCTAssertEqual(store.state, .error(lastKnown: .yes))
		XCTAssertEqual(store.lastCheckedAt, failedDate)
		XCTAssertEqual(store.menuBarTitle, "yes")
		XCTAssertNotNil(store.errorMessage)
	}

	@MainActor
	func testManualRefreshTriggersFetch() async {
		let checkedAt = makeDate(hour: 13, minute: 30, second: 2)
		let service = MockStatusService(results: [.success(FetchResult(state: .no, checkedAt: checkedAt))])
		let store = StatusStore(service: service, nowProvider: { checkedAt }, autoStart: false)
		let fetchExpectation = expectation(description: "manual fetch")
		service.onFetch = { fetchExpectation.fulfill() }

		store.refreshNow()
		await fulfillment(of: [fetchExpectation], timeout: 1)

		XCTAssertEqual(service.fetchCount, 1)
		XCTAssertEqual(store.state, .no)
	}

	func testNextPollDateAlignsToQuarterHourPlusTwoSeconds() {
		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = TimeZone(secondsFromGMT: 0)!

		let beforeBoundary = makeDate(hour: 13, minute: 0, second: 1, calendar: calendar)
		let exactBoundary = makeDate(hour: 13, minute: 0, second: 2, calendar: calendar)
		let midWindow = makeDate(hour: 13, minute: 7, second: 44, calendar: calendar)

		XCTAssertEqual(
			StatusStore.nextPollDate(after: beforeBoundary, calendar: calendar),
			makeDate(hour: 13, minute: 0, second: 2, calendar: calendar)
		)
		XCTAssertEqual(
			StatusStore.nextPollDate(after: exactBoundary, calendar: calendar),
			makeDate(hour: 13, minute: 15, second: 2, calendar: calendar)
		)
		XCTAssertEqual(
			StatusStore.nextPollDate(after: midWindow, calendar: calendar),
			makeDate(hour: 13, minute: 15, second: 2, calendar: calendar)
		)
	}

	private func makeDate(
		hour: Int,
		minute: Int,
		second: Int,
		calendar: Calendar = Calendar(identifier: .gregorian)
	) -> Date {
		var components = DateComponents()
		components.year = 2026
		components.month = 3
		components.day = 17
		components.hour = hour
		components.minute = minute
		components.second = second
		components.timeZone = calendar.timeZone
		return calendar.date(from: components)!
	}
}

private final class MockStatusService: StatusFetching, @unchecked Sendable {
	var results: [Result<FetchResult, Error>]
	var onFetch: (() -> Void)?
	var fetchCountHandler: ((Int) -> Void)?
	private(set) var fetchCount = 0

	init(results: [Result<FetchResult, Error>]) {
		self.results = results
	}

	func fetchStatus() async throws -> FetchResult {
		fetchCount += 1
		onFetch?()
		fetchCountHandler?(fetchCount)
		return try results.removeFirst().get()
	}
}

private enum MockError: LocalizedError {
	case network

	var errorDescription: String? {
		"Network failed"
	}
}
