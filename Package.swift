// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "GoTrue",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        .library(name: "GoTrue", targets: ["GoTrue"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/Flight-School/AnyCodable",
            from: "0.6.0"
        ),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.9.0"),
        .package(url: "https://github.com/grsouza/simple-http", .branch("main")),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.2.1")
    ],
    targets: [
        .target(
            name: "GoTrue",
            dependencies: [
                "AnyCodable",
                .product(name: "SimpleHTTP", package: "simple-http"),
                .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay")
            ]
        ),
        .testTarget(
            name: "GoTrueTests",
            dependencies: [
                "GoTrue", .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            exclude: [
                "__Snapshots__",
            ]
        ),
    ]
)
