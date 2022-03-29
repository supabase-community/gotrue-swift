// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "GoTrue",
  platforms: [
    .iOS(.v13),
    .macCatalyst(.v13),
    .macOS(.v10_15),
    .watchOS(.v6),
    .tvOS(.v13),
  ],
  products: [
    .library(name: "GoTrue", targets: ["GoTrue"])
  ],
  dependencies: [
    .package(url: "https://github.com/grsouza/swift-gotrue-http", branch: "main"),
    .package(url: "https://github.com/kean/Get", branch: "main"),
    .package(url: "https://github.com/binaryscraping/swift-composable-keychain", from: "0.0.2"),
  ],
  targets: [
    .target(
      name: "GoTrue",
      dependencies: [
        .product(name: "GoTrueHTTP", package: "swift-gotrue-http"),
        .product(name: "Get", package: "Get"),
        .product(name: "ComposableKeychain", package: "swift-composable-keychain"),
      ]
    ),
    .testTarget(name: "GoTrueTests", dependencies: ["GoTrue"]),
  ]
)
