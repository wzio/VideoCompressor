// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VideoCompressor",
    platforms: [
        .iOS(.v12), .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "VideoCompressor",
            targets: ["VideoCompressor"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VideoCompressor",
            dependencies: []),
        .testTarget(
            name: "VideoCompressorTests",
            dependencies: ["VideoCompressor"],
            resources: []),
    ]
)
