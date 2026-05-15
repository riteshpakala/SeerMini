// swift-tools-version: 5.10.0

import PackageDescription

let package = Package(
  name: "seer-mini",
  platforms: [.macOS(.v14)],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.3.0")),
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "4.2.0"),
  ],
  targets: [
    .executableTarget(
      name: "seer-mini",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Vapor", package: "vapor"),
        .product(name: "Crypto", package: "swift-crypto"),
      ],
      path: "Sources"
    )
  ]
)
