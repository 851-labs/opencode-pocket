// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "TranscriptUI",
  platforms: [
    .iOS("18.0"),
    .macOS("15.0"),
  ],
  products: [
    .library(name: "TranscriptUI", targets: ["TranscriptUI"]),
  ],
  dependencies: [
    .package(url: "https://github.com/gonzalezreal/textual", from: "0.1.0"),
  ],
  targets: [
    .target(
      name: "TranscriptUI",
      dependencies: [
        .product(name: "Textual", package: "textual"),
      ]
    ),
  ]
)
