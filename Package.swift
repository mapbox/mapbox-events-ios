// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MapboxMobileEvents",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "MapboxMobileEvents",
            targets: ["MapboxMobileEvents"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MapboxMobileEvents",
            dependencies: []
        ),
        .testTarget(
            name: "MapboxMobileEventsTests",
            dependencies: ["MapboxMobileEvents"],
            cSettings: [
                .headerSearchPath("Fakes"),
                .headerSearchPath("Utilities"),
                .headerSearchPath("../../Sources"),
                .headerSearchPath("../../Sources/MapboxMobileEvents")
            ]
        ),
        .testTarget(
            name: "MapboxMobileEventsSwiftTests",
            dependencies: ["MapboxMobileEvents"]
        ),
    ]
)
