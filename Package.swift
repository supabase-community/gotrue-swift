// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "GoTrue",
  platforms: [
    .iOS(.v11),
    .macOS(.v10_13),
    .tvOS(.v11),
  ],
  products: [
    .library(name: "GoTrue", targets: ["GoTrue"])
  ],
  dependencies: [
    .package(name: "AnyCodable", url: "https://github.com/Flight-School/AnyCodable", from: "0.6.2")
  ],
  targets: [
    .target(name: "GoTrue", dependencies: ["AnyCodable"]),
    .testTarget(name: "GoTrueTests", dependencies: ["GoTrue"]),
    .testTarget(name: "GoTrueIntegrationTests", dependencies: ["GoTrue"]),
  ]
)
