// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BMSwiftNetworking",
    platforms: [
        .iOS(.v13),
        .macOS(.v12),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BMSwiftNetworking",
            targets: ["BMSwiftNetworking"]),
    ],
    dependencies: [
        // Add your dependencies here
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BMSwiftNetworking",
            swiftSettings: [.define("BUILD_LIBRARY_FOR_DISTRIBUTION")]
        ),
        .testTarget(
            name: "BMSwiftNetworkingTests",
            dependencies: ["BMSwiftNetworking"]),
    ]
)
