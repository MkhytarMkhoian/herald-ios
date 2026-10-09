# Change Log

All Herald for iOS packages share one version, and this change log covers them all: `herald-ios`
and the five vendor packages.

## Version 1.0.0

_2026-10-09_

The first stable release, with the same API as 1.0.0-beta.2. From now on the API changes
incompatibly only in a major version.

## Version 1.0.0-beta.2

_2026-10-07_

 * New: `HeraldSwiftUI`, for tracking from SwiftUI views: `.eventTracker(_:)` gives views the
   tracker, `.trackScreenView(_:)` and `.track(_:on:)` track each time a screen is shown or hidden,
   and `.trackImpression(_:threshold:minVisibleDuration:)` tracks once per appearance, when enough
   of a view has been on screen long enough. On iOS 18 and newer, impressions also see what a
   scroll view cuts off.

## Version 1.0.0-beta.1

_2026-10-07_

The first preview of Herald for iOS: the design of the Android and Flutter SDKs, in Swift, over
each vendor's official iOS SDK.

 * New: `HeraldCore`: events and properties with typed values, the five capabilities, the factory
   chain and the `Herald` fan-out. Calls don't wait or throw; vendors report failures with
   `Herald.reportFailure`.
 * New: `HeraldLog`, which prints every call in the same format as the Android and Flutter SDKs.
 * New: `HeraldTesting`, with `FakeAnalyticsProvider` and its assertions, for Swift Testing and
   XCTest alike.
 * New: `HeraldFirebase`, `HeraldMixpanel`, `HeraldAmplitude`, `HeraldAdjust` and
   `HeraldAppsFlyer`, each in its own package, over Firebase 12, `mixpanel-swift` 6,
   `Amplitude-Swift` 1.12, Adjust 5 and AppsFlyer 7.
