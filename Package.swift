// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BetterQuickLook",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .binaryTarget(
            name: "VLCKit",
            path: "Frameworks/VLCKit.xcframework"
        ),
        .executableTarget(
            name: "VideoPreview",
            dependencies: [
                .target(name: "VLCKit")
            ]
        )
    ]
)
