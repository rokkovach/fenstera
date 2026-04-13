// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenCodeController",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "OpenCodeController", targets: ["OpenCodeController"]),
    ],
    targets: [
        .target(
            name: "OpenCodeController",
            path: "Sources/OpenCodeController",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
    ]
)
