// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DragWheel",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "DragWheel", path: "Sources/DragWheel")
    ]
)
