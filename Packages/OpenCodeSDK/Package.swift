// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "OpenCodeSDK",
  platforms: [
    .iOS(.v17),
    .macOS(.v12),
  ],
  products: [
    .library(name: "OpenCodeSDK", targets: ["OpenCodeSDK"]),
  ],
  targets: [
    .target(
      name: "OpenCodeSDK",
      path: "Sources/OpenCodeSDK"
    ),
    .testTarget(
      name: "OpenCodeSDKTests",
      dependencies: [
        "OpenCodeSDK",
      ],
      path: "Tests/OpenCodeSDKTests"
    ),
  ]
)
