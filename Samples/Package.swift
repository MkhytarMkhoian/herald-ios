// swift-tools-version: 6.0
import PackageDescription

// The Swift code on the Herald website. Its pages include marked sections of these files, and CI
// builds and tests them, so an example that stops compiling fails CI instead of going stale.
//
// It's a package of its own, so apps that add herald-ios never see it or its dependencies.
let package = Package(
    name: "herald-ios-samples",
    // Adjust's SDK builds for iOS only, and the SwiftUI samples use NavigationStack.
    platforms: [.iOS(.v16)],
    dependencies: [
        .package(path: ".."),
        .package(path: "../../herald-ios-firebase"),
        .package(path: "../../herald-ios-mixpanel"),
        .package(path: "../../herald-ios-amplitude"),
        .package(path: "../../herald-ios-adjust"),
        .package(path: "../../herald-ios-appsflyer"),
        // The vendor SDKs, for the samples that call them directly.
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.0.0"),
        .package(url: "https://github.com/mixpanel/mixpanel-swift", from: "6.0.0"),
        .package(url: "https://github.com/amplitude/Amplitude-Swift", from: "1.12.0"),
        .package(url: "https://github.com/adjust/ios_sdk", from: "5.0.0"),
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "Samples",
            dependencies: [
                .product(name: "HeraldCore", package: "herald-ios"),
                .product(name: "HeraldLog", package: "herald-ios"),
                .product(name: "HeraldSwiftUI", package: "herald-ios"),
                .product(name: "HeraldFirebase", package: "herald-ios-firebase"),
                .product(name: "HeraldMixpanel", package: "herald-ios-mixpanel"),
                .product(name: "HeraldAmplitude", package: "herald-ios-amplitude"),
                .product(name: "HeraldAdjust", package: "herald-ios-adjust"),
                .product(name: "HeraldAppsFlyer", package: "herald-ios-appsflyer"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "Mixpanel", package: "mixpanel-swift"),
                .product(name: "AmplitudeSwift", package: "Amplitude-Swift"),
                .product(name: "AdjustSdk", package: "ios_sdk"),
                .product(name: "AppsFlyerLib", package: "AppsFlyerFramework"),
            ]
        ),
        .testTarget(
            name: "SamplesTests",
            dependencies: [
                "Samples",
                .product(name: "HeraldTesting", package: "herald-ios"),
            ]
        ),
    ]
)
