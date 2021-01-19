// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let checksum = "d14f95248e1a6557b08d811e161114d2955ea3e439b9cb43537eeae5972a9a13"
let url = "https://github.com/mapbox/mapbox-events-ios/releases/download/v0.12.0-alpha.1/MapboxMobileEvents.xcframework.zip"

let package = Package(
    name: "MapboxMobileEvents",
    platforms: [.iOS(.v9)],
    products: [
        .library(
            name: "MapboxMobileEvents",
            targets: ["MapboxMobileEvents"]),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(name: "MapboxMobileEvents", url: url, checksum: checksum)
    ],
    cxxLanguageStandard: .cxx14
)
