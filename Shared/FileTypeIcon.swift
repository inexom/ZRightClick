import AppKit

extension FileTypeDefinition {
    var icon: NSImage {
        let tint: NSColor
        switch color {
        case "blue": tint = .systemBlue
        case "green": tint = .systemGreen
        case "orange": tint = .systemOrange
        case "indigo": tint = .systemIndigo
        default: tint = .secondaryLabelColor
        }
        let source = NSImage(systemSymbolName: symbol, accessibilityDescription: name)?
            .withSymbolConfiguration(.init(pointSize: 14, weight: .regular))
        return NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            guard let source else { return false }
            source.draw(in: rect.insetBy(dx: 1, dy: 1))
            tint.setFill()
            rect.fill(using: .sourceAtop)
            return true
        }
    }
}
