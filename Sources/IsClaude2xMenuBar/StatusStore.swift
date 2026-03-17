import AppKit
import Foundation
import ServiceManagement
import SwiftUI

@MainActor
final class StatusStore: ObservableObject {
	@Published private(set) var state: Claude2XState = .loading
	@Published private(set) var lastCheckedAt: Date?
	@Published private(set) var errorMessage: String?
	@Published private(set) var isRefreshing = false
	@Published var launchAtLoginEnabled: Bool

	private nonisolated let service: any StatusFetching
	private let calendar: Calendar
	private let nowProvider: () -> Date
	private var refreshTimer: Timer?
	private var refreshTask: Task<Void, Never>?

	init(
		service: StatusFetching = StatusService(),
		calendar: Calendar = .current,
		nowProvider: @escaping () -> Date = Date.init,
		autoStart: Bool = true
	) {
		self.service = service
		self.calendar = calendar
		self.nowProvider = nowProvider
		launchAtLoginEnabled = Self.readLaunchAtLoginStatus()

		if autoStart {
			start()
		}
	}

	var menuBarTitle: String {
		displayedKnownState?.rawValue ?? "..."
	}

	var menuBarImage: NSImage {
		StatusBarLabelImageRenderer.makeImage(
			text: menuBarTitle,
			color: displayedKnownState?.statusBarColor ?? .secondaryLabelColor
		)
	}

	var statusLine: String {
		switch state {
		case .loading:
			return "Status: checking..."
		case .yes:
			return Claude2XKnownState.yes.menuDescription
		case .no:
			return Claude2XKnownState.no.menuDescription
		case let .error(lastKnown):
			if let lastKnown {
				return "Status: \(lastKnown.rawValue) (stale)"
			}

			return "Status: unavailable"
		}
	}

	func refreshNow() {
		guard refreshTask == nil else {
			return
		}

		isRefreshing = true
		refreshTask = Task { [weak self] in
			guard let self else {
				return
			}

			await self.performRefresh()
			await MainActor.run {
				self.isRefreshing = false
				self.refreshTask = nil
			}
		}
	}

	func openWebsite() {
		guard let url = URL(string: "https://isclaude2x.com") else {
			return
		}

		NSWorkspace.shared.open(url)
	}

	func setLaunchAtLoginEnabled(_ enabled: Bool) {
		do {
			if enabled {
				try SMAppService.mainApp.register()
			} else {
				try SMAppService.mainApp.unregister()
			}
			launchAtLoginEnabled = Self.readLaunchAtLoginStatus()
		} catch {
			launchAtLoginEnabled = Self.readLaunchAtLoginStatus()
			errorMessage = "Launch at login update failed: \(error.localizedDescription)"
		}
	}

	func quit() {
		NSApplication.shared.terminate(nil)
	}

	nonisolated static func nextPollDate(after now: Date, calendar: Calendar = .current) -> Date {
		var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
		let minute = components.minute ?? 0
		components.minute = minute - (minute % 15)
		components.second = 2

		let candidate = calendar.date(from: components) ?? now
		if candidate > now {
			return candidate
		}

		return calendar.date(byAdding: .minute, value: 15, to: candidate) ?? now.addingTimeInterval(900)
	}

	private var displayedKnownState: Claude2XKnownState? {
		state.lastKnownState
	}

	private func start() {
		refreshNow()
		scheduleRefreshTimer()
	}

	private func scheduleRefreshTimer() {
		refreshTimer?.invalidate()

		let firstFireDate = Self.nextPollDate(after: nowProvider(), calendar: calendar)
		let timer = Timer(fire: firstFireDate, interval: 15 * 60, repeats: true) { [weak self] _ in
			Task { @MainActor [weak self] in
				self?.refreshNow()
			}
		}
		timer.tolerance = 1

		RunLoop.main.add(timer, forMode: .common)
		refreshTimer = timer
	}

	private func performRefresh() async {
		do {
			let result = try await service.fetchStatus()
			lastCheckedAt = result.checkedAt
			errorMessage = nil
			state = result.state == .yes ? .yes : .no
		} catch {
			lastCheckedAt = nowProvider()
			errorMessage = error.localizedDescription
			state = .error(lastKnown: state.lastKnownState)
		}
	}

	private static func readLaunchAtLoginStatus() -> Bool {
		SMAppService.mainApp.status == .enabled
	}
}
