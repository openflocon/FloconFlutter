// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flocon",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "flocon", targets: ["flocon"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flocon",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("Resources/PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
