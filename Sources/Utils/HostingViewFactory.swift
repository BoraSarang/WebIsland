import Cocoa
import SwiftUI

/// 수동 크기 오버레이용 호스팅 뷰 공장.
/// `NSHostingView` 기본값(콘텐츠 자동 맞춤)을 끄고 윈도우 크기를 추적한다.
/// 노치·분리·디버그·온보딩 4곳의 보일러플레이트 통합.
enum HostingViewFactory {
    static func make<Content: View>(rootView: Content, size: NSSize) -> NSHostingView<Content> {
        let hosting = NSHostingView(rootView: rootView)
        hosting.sizingOptions = []
        hosting.frame = NSRect(origin: .zero, size: size)
        hosting.autoresizingMask = [.width, .height]
        return hosting
    }
}
