// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WebIsland",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "WebIsland", targets: ["WebIsland"])],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0")
    ],
    targets: [
        .executableTarget(name: "WebIsland", dependencies: ["KeyboardShortcuts"], path: "Sources")
    ]
)
