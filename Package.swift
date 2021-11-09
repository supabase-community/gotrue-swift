// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GoTrue",
    products: [
        .library(name: "GoTrue", targets: ["GoTrue"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/Flight-School/AnyCodable",
            from: "0.6.0"
        ),
    ],
    targets: [
        .target(name: "GoTrue", dependencies: ["AnyCodable"]),
        .testTarget(name: "GoTrueTests", dependencies: ["GoTrue"]),
    ]
)
