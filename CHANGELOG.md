# Change Log

All Herald for iOS packages share one version, and this change log covers them all: `herald-ios`
and the six vendor packages.

## Version 1.3.0

_Not released yet_

 * New: `herald-ios-meta`, module `HeraldMeta`, sends events to Meta's App Events, over Meta's iOS
   SDK 18: conversions under Meta's standard names, and purchases through `MetaPurchaseEvent`.

## Version 1.2.0

_2026-10-17_

 * Breaking: `TokenAdjustEventTrackerFactory` takes a list of `AdjustToken`s, each pairing a token
   with an event type, instead of a map from event names:
   `TokenAdjustEventTrackerFactory(tokens: [AdjustToken(SignUpCompleted.self, "abc123")])`. A renamed
   event keeps its token, the compiler checks the list, and an event of a subclass of a listed class
   uses its token too. A type listed twice stops the app at start-up.
 * Fix: `HeraldSwiftUI`'s docs give Control Center, not Notification Center, as an example of the
   app briefly losing focus. Notification Center sends the app to the background, so it hides the
   screen. The behaviour doesn't change.

## Version 1.1.0

_2026-10-12_

 * New: `HeraldInterop`, for Kotlin Multiplatform apps: `HeraldBridge` lets shared Kotlin code,
   through [herald-kmp](https://github.com/MkhytarMkhoian/herald-kmp), use a `Herald` set up in
   Swift. `translate` turns Kotlin vendor events, such as revenue, into herald-ios's, and a vendor
   event left untranslated goes to the error reporter. `event.kotlinEvent` lets factories check
   shared Kotlin labels.

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
