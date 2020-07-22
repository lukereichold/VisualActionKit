// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VisualActionKit",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "VisualActionKit",
            targets: ["VisualActionKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VisualActionKit",
            dependencies: [],
            resources: [
                .process("Kinetics.mlmodel")
            ]),
        .testTarget(
            name: "VisualActionKitTests",
            dependencies: ["VisualActionKit"],
            resources: [
                .process("Test Videos")
            ])
    ]
)
