import Foundation

enum StatusServiceError: LocalizedError, Equatable {
	case invalidResponse
	case unexpectedStatusCode(Int)
	case invalidPayload(String)

	var errorDescription: String? {
		switch self {
		case .invalidResponse:
			return "The server returned an invalid response."
		case let .unexpectedStatusCode(code):
			return "The server returned HTTP \(code)."
		case let .invalidPayload(payload):
			return "Unexpected response payload: \(payload)"
		}
	}
}

struct StatusService: StatusFetching {
	private let session: URLSession
	private let endpoint: URL

	init(
		session: URLSession = .shared,
		endpoint: URL = URL(string: "https://isclaude2x.com/short")!
	) {
		self.session = session
		self.endpoint = endpoint
	}

	func fetchStatus() async throws -> FetchResult {
		var request = URLRequest(url: endpoint)
		request.cachePolicy = .reloadIgnoringLocalCacheData
		request.timeoutInterval = 15

		let (data, response) = try await session.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw StatusServiceError.invalidResponse
		}

		guard httpResponse.statusCode == 200 else {
			throw StatusServiceError.unexpectedStatusCode(httpResponse.statusCode)
		}

		let state = try Self.parseKnownState(from: data)
		return FetchResult(state: state, checkedAt: Date())
	}

	static func parseKnownState(from data: Data) throws -> Claude2XKnownState {
		let payload = String(decoding: data, as: UTF8.self)
		let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

		switch trimmed {
		case Claude2XKnownState.yes.rawValue:
			return .yes
		case Claude2XKnownState.no.rawValue:
			return .no
		default:
			throw StatusServiceError.invalidPayload(trimmed.isEmpty ? "<empty>" : trimmed)
		}
	}
}
