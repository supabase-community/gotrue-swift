// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "gotrue-swift",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .watchOS(.v3),
    ],
    products: [
        .library(name: "gotrue", targets: ["gotrue"]),
        .executable(name: "example", targets: ["example"]),
    ],
    targets: [
        .target(name: "gotrue"),
        .target(name: "example", dependencies: ["gotrue"]),
    ]
)
