import Cocoa

/// 노치 프레임 계산 (순수 함수 — 단위 테스트 대상).
enum NotchDetector {
    /// - Parameters:
    ///   - left: `auxiliaryTopLeftArea`, right: `auxiliaryTopRightArea`
    /// - Returns: 노치 영역. 노치 없으면 nil.
    static func rect(left: NSRect, right: NSRect) -> NSRect? {
        guard left.width > 0, right.minX > left.maxX + 10 else { return nil }
        return NSRect(
            x: left.maxX,
            y: left.minY,
            width: right.minX - left.maxX,
            height: left.height
        )
    }

    static func isHover(
        mouse: NSPoint,
        notch: NSRect,
        expandedWidth: CGFloat = 420,
        padding: CGFloat = 20
    ) -> Bool {
        let expanded = NSRect(
            x: notch.midX - expandedWidth / 2,
            y: notch.minY,
            width: expandedWidth,
            height: 40
        ).insetBy(dx: -padding, dy: -padding)
        return expanded.contains(mouse)
    }
}

extension NSScreen {
    var notchRect: NSRect? {
        guard let left = auxiliaryTopLeftArea,
              let right = auxiliaryTopRightArea
        else { return nil }
        return NotchDetector.rect(left: left, right: right)
    }

    var hasNotch: Bool { notchRect != nil }
}
