// swift-tools-version: 5.10.0

import PackageDescription

let package = Package(
    name: "SeerDemo",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "SeerDemo",
            path: "Sources",
            resources: [.process("Resources")]
        )
    ]
)
