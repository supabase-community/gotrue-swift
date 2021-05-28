// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GoTrue",
    products: [
        .library(name: "GoTrue", targets: ["GoTrue"]),
    ],
    targets: [
        .target(name: "GoTrue", dependencies: []),
        .testTarget(name: "GoTrueTests", dependencies: ["GoTrue"]),
    ]
)
