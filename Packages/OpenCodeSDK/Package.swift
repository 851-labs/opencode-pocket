// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "OpenCodeSDK",
  platforms: [
    .iOS(.v17),
    .macOS(.v12),
  ],
  products: [
    .library(name: "OpenCodeModels", targets: ["OpenCodeModels"]),
    .library(name: "OpenCodeNetworking", targets: ["OpenCodeNetworking"]),
  ],
  targets: [
    .target(name: "OpenCodeModels"),
    .target(
      name: "OpenCodeNetworking",
      dependencies: [
        "OpenCodeModels",
      ]
    ),
    .testTarget(
      name: "OpenCodeNetworkingTests",
      dependencies: [
        "OpenCodeNetworking",
        "OpenCodeModels",
      ],
      exclude: [
        "APP_CLIENT_PARITY_COVERAGE.md",
      ]
    ),
  ]
)
