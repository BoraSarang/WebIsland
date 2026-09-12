import Cocoa

/// 파비콘 폴백용 첫글자 아바타 생성 (해시 그라데이션).
enum AvatarGenerator {
    static func generate(for host: String) -> NSImage {
        let letter = String(host.prefix(1)).uppercased()
        let colors = gradient(for: host)
        let size = NSSize(width: 64, height: 64)
        let img = NSImage(size: size)
        img.lockFocus()
        let path = NSBezierPath(
            roundedRect: NSRect(origin: .zero, size: size),
            xRadius: 14,
            yRadius: 14
        )
        NSGraphicsContext.saveGraphicsState()
        path.addClip()
        let gradient = NSGradient(colors: colors)!
        gradient.draw(
            in: NSRect(origin: .zero, size: size),
            angle: 45
        )
        NSGraphicsContext.restoreGraphicsState()
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.boldSystemFont(ofSize: 28),
        ]
        let strSize = letter.size(withAttributes: attrs)
        letter.draw(
            at: NSPoint(x: (64 - strSize.width) / 2, y: (64 - strSize.height) / 2),
            withAttributes: attrs
        )
        img.unlockFocus()
        return img
    }

    static func gradient(for string: String) -> [NSColor] {
        let hash = abs(string.hashValue)
        let palettes: [[NSColor]] = [
            [.systemBlue, .systemPurple],
            [.systemPink, .systemOrange],
            [.systemGreen, .systemTeal],
            [.systemIndigo, .systemBlue],
        ]
        return palettes[hash % palettes.count]
    }
}
