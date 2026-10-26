import AppKit

// A vector-drawn, bilingual 2x background. No Finder automation is needed.
let size = NSSize(width: 720, height: 440)
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1440, pixelsHigh: 880,
                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                              isPlanar: false, colorSpaceName: .deviceRGB,
                              bytesPerRow: 0, bitsPerPixel: 0)!
bitmap.size = size
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor(calibratedRed: 0.97, green: 0.98, blue: 1, alpha: 1).setFill()
NSRect(origin: .zero, size: size).fill()

func text(_ value: String, x: CGFloat, top: CGFloat, size: CGFloat,
          weight: NSFont.Weight = .regular, secondary: Bool = false) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: secondary ? NSColor(calibratedWhite: 0.43, alpha: 1)
            : NSColor(calibratedRed: 0.08, green: 0.14, blue: 0.25, alpha: 1)
    ]
    let string = NSAttributedString(string: value, attributes: attributes)
    string.draw(at: NSPoint(x: x, y: 440 - top - string.size().height))
}
text("ZRightClick", x: 44, top: 30, size: 26, weight: .bold)
text("拖入应用程序，即可安装", x: 44, top: 72, size: 16, weight: .medium)
text("Drag ZRightClick into Applications to install.", x: 44, top: 98, size: 12, secondary: true)

let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 332, y: 215))
arrow.line(to: NSPoint(x: 388, y: 215))
arrow.move(to: NSPoint(x: 375, y: 228))
arrow.line(to: NSPoint(x: 388, y: 215))
arrow.line(to: NSPoint(x: 375, y: 202))
arrow.lineWidth = 4
arrow.lineCapStyle = .round
arrow.lineJoinStyle = .round
NSColor(calibratedRed: 0.30, green: 0.50, blue: 0.84, alpha: 0.8).setStroke()
arrow.stroke()

text("安装后打开 ZRightClick，跟随引导启用访达扩展。", x: 44, top: 366, size: 13)
text("After installation, open ZRightClick to enable the Finder extension.",
     x: 44, top: 391, size: 11, secondary: true)
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
