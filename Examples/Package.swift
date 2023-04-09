// swift-tools-version:5.5

import PackageDescription

// let package = Package(
//   name: "Examples",
//   platforms: [],
//   products: [],
//   dependencies: [],
//   targets: []
// )

let packageName = "Shared" // <-- Change this to yours
let package = Package(
  name: "",
  // platforms: [.iOS("9.0")],
  products: [
    .library(name: packageName, targets: [packageName])
  ],
  targets: [
    .target(
      name: packageName,
      path: packageName
    )
  ]
)
