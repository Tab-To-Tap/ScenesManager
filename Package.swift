// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

/// ScenesManager: A visionOS Scene Management Package
///
/// Created by Tom Krikorian and Tina Debove Nigro
let package = Package(
    name: "ScenesManager",
    platforms: [
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "ScenesManager",
            targets: ["ScenesManager"]),
    ],
    targets: [
        .target(
            name: "ScenesManager"),
    ]
)
