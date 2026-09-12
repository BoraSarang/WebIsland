import Cocoa

// Main nib/storyboard 없이 델리게이트를 직접 연결.
// (@main만으로는 NSApplicationMain이 델리게이트를 찾지 못해
// applicationDidFinishLaunching이 호출되지 않음)
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
