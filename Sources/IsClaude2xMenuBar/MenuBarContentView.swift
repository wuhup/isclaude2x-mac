import SwiftUI

struct MenuBarContentView: View {
	@ObservedObject var store: StatusStore

	var body: some View {
		Text(store.statusLine)

		if let lastCheckedAt = store.lastCheckedAt {
			Text("Last checked: \(lastCheckedAt.formatted(date: .omitted, time: .standard))")
		} else {
			Text("Last checked: never")
		}

		if let errorMessage = store.errorMessage {
			Text(errorMessage)
				.font(.caption)
				.foregroundStyle(.secondary)
		}

		Divider()

		Button(store.isRefreshing ? "Refreshing..." : "Refresh Now") {
			store.refreshNow()
		}
		.disabled(store.isRefreshing)

		Button("Open Website") {
			store.openWebsite()
		}

		Toggle(isOn: launchAtLoginBinding) {
			Text("Launch at Login")
		}

		Divider()

		Button("Quit") {
			store.quit()
		}
	}

	private var launchAtLoginBinding: Binding<Bool> {
		Binding(
			get: { store.launchAtLoginEnabled },
			set: { store.setLaunchAtLoginEnabled($0) }
		)
	}
}
