// swift-tools-version: 5.10.0

import PackageDescription

let package = Package(
  name: "seer-mini",
  platforms: [.macOS(.v14)],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.3.0")),
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "4.2.0"),
    .package(url: "https://github.com/riteshpakala/mlx.embeddings.git", branch: "main"),
    .package(url: "https://github.com/riteshpakala/mlx-swift-lm", branch: "main"),
  ],
  targets: [
    .executableTarget(
      name: "seer-mini",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Vapor", package: "vapor"),
        .product(name: "Crypto", package: "swift-crypto"),
        .product(name: "MLXLMCommon", package: "mlx-swift-lm"),  // uncomment with MLX packages above
        .product(name: "mlx_embeddings", package: "mlx.embeddings"),   // uncomment with MLX packages above
      ],
      path: "Sources"
    ),
    .testTarget(
      name: "seer-mini-tests",
      dependencies: ["seer-mini"],
      path: "Tests/seer-mini-tests"
    )
  ]
)
