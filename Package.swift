// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "herald-ios",
    // macOS is listed so the core modules can be built and tested with `swift test` on a Mac.
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(name: "HeraldCore", targets: ["HeraldCore"])
    ],
    targets: [
        .target(name: "HeraldCore"),
        .testTarget(name: "HeraldCoreTests", dependencies: ["HeraldCore"]),
    ]
)
