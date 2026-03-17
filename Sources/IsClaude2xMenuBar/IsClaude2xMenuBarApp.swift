import SwiftUI

@main
struct IsClaude2xMenuBarApp: App {
	@StateObject private var store = StatusStore()

	var body: some Scene {
		MenuBarExtra {
			MenuBarContentView(store: store)
		} label: {
			Image(nsImage: store.menuBarImage)
		}
		.menuBarExtraStyle(.menu)
	}
}
