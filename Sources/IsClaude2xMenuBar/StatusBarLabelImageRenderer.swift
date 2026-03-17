import AppKit
import Foundation

enum StatusBarLabelImageRenderer {
	static func makeImage(text: String, color: NSColor) -> NSImage {
		let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
		let attributes: [NSAttributedString.Key: Any] = [
			.font: font,
			.foregroundColor: color
		]
		let attributedText = NSAttributedString(string: text, attributes: attributes)
		let textSize = attributedText.size()
		let size = NSSize(width: ceil(textSize.width), height: ceil(textSize.height))
		let image = NSImage(size: size)

		image.lockFocus()
		attributedText.draw(at: .zero)
		image.unlockFocus()
		image.isTemplate = false

		return image
	}
}
