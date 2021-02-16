// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RestKit",
    platforms: [.iOS("13.0")],
    products: [
        .library(name: "RestKit", targets: ["RestKit"]),
    ],
    targets: [
        .target(name: "RestKit"),
        .testTarget(name: "RestKitTests", dependencies: ["RestKit"])
    ]
)
