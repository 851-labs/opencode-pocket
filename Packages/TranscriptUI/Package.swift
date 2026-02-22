// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "TranscriptUI",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
  ],
  products: [
    .library(name: "TranscriptUI", targets: ["TranscriptUI"]),
  ],
  targets: [
    .target(name: "TranscriptUI"),
  ]
)
