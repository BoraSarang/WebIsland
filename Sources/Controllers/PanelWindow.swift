import Cocoa

/// 오버레이용 윈도우. 텍스트 입력(옴니박스)·단축키를 위해 키 윈도우 허용.
/// (`.nonactivatingPanel`만으로는 키가 안 되어 TextField 입력 불가)
final class PanelWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}
