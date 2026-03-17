import Foundation
import SwiftUI
import AppKit

enum Claude2XKnownState: String, Equatable {
	case yes
	case no

	var color: Color {
		switch self {
		case .yes:
			return .green
		case .no:
			return .red
		}
	}

	var menuDescription: String {
		"Status: \(rawValue)"
	}

	var statusBarColor: NSColor {
		switch self {
		case .yes:
			return .systemGreen
		case .no:
			return .systemRed
		}
	}
}

enum Claude2XState: Equatable {
	case loading
	case yes
	case no
	case error(lastKnown: Claude2XKnownState?)

	var lastKnownState: Claude2XKnownState? {
		switch self {
		case .yes:
			return .yes
		case .no:
			return .no
		case .loading:
			return nil
		case let .error(lastKnown):
			return lastKnown
		}
	}
}

struct FetchResult: Equatable {
	let state: Claude2XKnownState
	let checkedAt: Date
}

protocol StatusFetching: Sendable {
	func fetchStatus() async throws -> FetchResult
}
