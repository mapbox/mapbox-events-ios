// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MapboxMobileEvents",
    platforms: [.iOS(.v8)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "MapboxMobileEvents",
            targets: ["MapboxMobileEvents"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "MapboxMobileEvents",
            dependencies: [],
            path: "MapboxMobileEvents",
            exclude: ["Info.plist", "Resources"],
            sources: ["Categories", "Reachability", "."]
            ,
            cSettings: [CSetting.headerSearchPath("MapboxMobileEvents/Categories"),
                        CSetting.headerSearchPath("MapboxMobileEvents/Reachability"),
                        CSetting.headerSearchPath("MapboxMobileEvents/")]
        ),
        .testTarget(
            name: "MapboxMobileEventsTests",
            dependencies: ["MapboxMobileEvents"],
            path: "Tests"
        ),
    ]
)



/*
 
 // swift-tools-version:5.2
 // The swift-tools-version declares the minimum version of Swift required to build this package.

 import PackageDescription

 //Package(name: <#T##String#>, platforms: <#T##[SupportedPlatform]?#>, pkgConfig: <#T##String?#>, providers: <#T##[SystemPackageProvider]?#>, products: <#T##[Product]#>, dependencies: <#T##[Package.Dependency]#>, targets: <#T##[Target]#>, swiftLanguageVersions: <#T##[SwiftVersion]?#>, cLanguageStandard: <#T##CLanguageStandard?#>, cxxLanguageStandard: <#T##CXXLanguageStandard?#>)
 let package = Package(
     name: "MapboxMobileEvents",
     platforms: [.iOS(.v8)],
     products: [
         // Products define the executables and libraries produced by a package, and make them visible to other packages.
         .library(
             name: "MapboxMobileEvents",
             targets: ["MapboxMobileEvents"]),
     ],
     dependencies: [
         // Dependencies declare other packages that this package depends on.
         // .package(url: /* package url */, from: "1.0.0"),
     ],
     targets: [
         // Targets are the basic building blocks of a package. A target can define a module or a test suite.
         // Targets can depend on other targets in this package, and on products in packages which this package depends on.
 //        .target(name: <#T##String#>, dependencies: <#T##[Target.Dependency]#>, path: <#T##String?#>, exclude: <#T##[String]#>, sources: <#T##[String]?#>, publicHeadersPath: <#T##String?#>, cSettings: <#T##[CSetting]?#>, cxxSettings: <#T##[CXXSetting]?#>, swiftSettings: <#T##[SwiftSetting]?#>, linkerSettings: <#T##[LinkerSetting]?#>)
         .target(
             name: "MapboxMobileEvents",
             dependencies: [])
 //        ,
 //        .testTarget(
 //            name: "MapboxMobileEventsTests",
 //            dependencies: ["MapboxMobileEvents"]),
     ]
 )

 
 
 
 */
