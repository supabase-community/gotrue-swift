// swift-tools-version:5.7
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
    .library(name: "GoTrue", targets: ["GoTrue"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kean/Get", from: "2.1.4"),
    .package(url: "https://github.com/kean/URLQueryEncoder", from: "0.2.0"),
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2"),
    .package(url: "https://github.com/WeTransfer/Mocker", from: "3.0.0"),
  ],
  targets: [
    .target(
      name: "GoTrue",
      dependencies: [
        .product(name: "Get", package: "Get"),
        .product(name: "KeychainAccess", package: "KeychainAccess"),
        .product(name: "URLQueryEncoder", package: "URLQueryEncoder"),
      ]
    ),
    .testTarget(
      name: "GoTrueTests",
      dependencies: ["GoTrue", "Mocker"],
      resources: [
        .process("Resources"),
      ]
    ),
  ]
)
