// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "herald-ios",
    // macOS is listed so the core modules can be built and tested with `swift test` on a Mac.
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(name: "HeraldCore", targets: ["HeraldCore"]),
        .library(name: "HeraldLog", targets: ["HeraldLog"]),
        .library(name: "HeraldTesting", targets: ["HeraldTesting"]),
    ],
    targets: [
        .target(name: "HeraldCore"),
        .testTarget(name: "HeraldCoreTests", dependencies: ["HeraldCore"]),

        .target(name: "HeraldLog", dependencies: ["HeraldCore"]),
        .testTarget(name: "HeraldLogTests", dependencies: ["HeraldLog", "HeraldTesting"]),

        .target(name: "HeraldTesting", dependencies: ["HeraldCore"]),
        .testTarget(name: "HeraldTestingTests", dependencies: ["HeraldTesting"]),
    ]
)
