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
            name: "BetterQuickLook",
            dependencies: [
                .target(name: "VLCKit")
            ],
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-rpath",
                    "-Xlinker", "@executable_path/../../../Frameworks/VLCKit.xcframework/macos-arm64_x86_64",
                    "-F", "Frameworks/VLCKit.xcframework/macos-arm64_x86_64"
                ])
            ]
        )
    ]
)
