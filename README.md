<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/MkhytarMkhoian/herald/main/docs/assets/readme-banner-dark.png">
  <img alt="Herald" src="https://raw.githubusercontent.com/MkhytarMkhoian/herald/main/docs/assets/readme-banner-light.png">
</picture>

> *A herald announces an event to whoever is listening.*

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Docs](https://img.shields.io/badge/docs-website-indigo.svg)](https://mkhytarmkhoian.github.io/herald-docs/)

Herald is an analytics library for mobile apps. Your app describes what happened as an event, and
Herald sends that event to every analytics service you use: Firebase, Adjust, Mixpanel, AppsFlyer,
Amplitude, or one you build yourself.

This repository is the **iOS SDK**, in Swift. It is the same design as the
[Android](https://github.com/MkhytarMkhoian/herald) and
[Flutter](https://github.com/MkhytarMkhoian/herald-flutter) SDKs: the same events, capabilities,
factories and vendor rules.

> **Beta.** Version 1.0.0-beta.1 is the first release, so you can try it before its API is fixed
> at 1.0.0.

## Install

In Xcode, choose File → Add Package Dependencies, and add `herald-ios` and one package for each
analytics service you use. In a `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/MkhytarMkhoian/herald-ios", from: "1.0.0-beta.1"),
    .package(url: "https://github.com/MkhytarMkhoian/herald-ios-firebase", from: "1.0.0-beta.1"),
]
```

All packages share one version. Each vendor package pulls in that vendor's SDK, and only an app
that adds it downloads that SDK.

## In 30 seconds

An event is a type your app owns:

```swift
struct CheckoutStarted: Event {
    let plan: String
    let seats: Int

    var name: String { "checkout_started" }
    var parameters: [String: AnalyticsValue] { ["plan": .string(plan), "seats": .int(seats)] }
}
```

Your classes ask for a small protocol, not for Herald or a vendor SDK:

```swift
final class CheckoutViewModel {
    private let analytics: any EventTrackerService

    init(analytics: any EventTrackerService) {
        self.analytics = analytics
    }

    func checkout(plan: String, seats: Int) {
        analytics.track(CheckoutStarted(plan: plan, seats: seats))
    }
}
```

`track` sends the event to every vendor before it returns. There's no `await` and no `try`: vendor
SDKs do their own work in the background, and a vendor that fails is reported to your error
reporter instead of to your code.

## Packages

<!-- The marked sections below also appear on the website's iOS page, so their links are absolute.
-->

<!-- --8<-- [start:packages] -->
| Package | Modules | What it is |
| --- | --- | --- |
| [`herald-ios`](https://github.com/MkhytarMkhoian/herald-ios) | `HeraldCore` | Events, properties and `Herald` itself. No vendor SDK or DI library. |
| | `HeraldLog` | Prints every call, for debug builds. |
| | `HeraldTesting` | `FakeAnalyticsProvider`, a fake vendor that records events so your tests can check them. |
| [`herald-ios-firebase`](https://github.com/MkhytarMkhoian/herald-ios-firebase) | `HeraldFirebase` | Sends to Firebase Analytics (GA4). |
| [`herald-ios-mixpanel`](https://github.com/MkhytarMkhoian/herald-ios-mixpanel) | `HeraldMixpanel` | Sends to Mixpanel: events, user profile and super properties. |
| [`herald-ios-amplitude`](https://github.com/MkhytarMkhoian/herald-ios-amplitude) | `HeraldAmplitude` | Sends to Amplitude: events, user properties, screen views and revenue. |
| [`herald-ios-adjust`](https://github.com/MkhytarMkhoian/herald-ios-adjust) | `HeraldAdjust` | Sends to Adjust: events by dashboard token, purchases and ad revenue. |
| [`herald-ios-appsflyer`](https://github.com/MkhytarMkhoian/herald-ios-appsflyer) | `HeraldAppsFlyer` | Sends to AppsFlyer: conversions, purchases, subscriptions and ad revenue. |
<!-- --8<-- [end:packages] -->

## Compatibility

<!-- --8<-- [start:compatibility] -->
Herald needs iOS 15 or newer and Xcode 16 or newer, and is written in Swift 6. It is built and
tested against these vendor SDKs:

| SDK | Version |
| --- | --- |
| Firebase | 12 |
| `mixpanel-swift` | 6 |
| `Amplitude-Swift` | 1.12 or newer |
| Adjust | 5 |
| AppsFlyer | 7 |

Each vendor package allows newer versions of its SDK within the same major version. A new major
version of an SDK may need a Herald release.
<!-- --8<-- [end:compatibility] -->

## Swift specifics

<!-- --8<-- [start:differences] -->
Herald's concepts are the same on every platform. Where Swift differs, the API follows Swift:

- **Calls don't wait or throw.** `track`, `set`, `identify` and the rest return once every vendor
  has the call: no `await`, no `try`. Vendor SDKs do their own work in the background, so a call
  takes very little time. A provider of your own must return quickly too, and do slow work, such
  as a network request, in a `Task`.
- **Vendors report failures instead of throwing them.** A vendor that can't send a call passes the
  error to `Herald.reportFailure`, and Herald sends it to your error reporter with the vendor's
  name and the call.
- **Setup mistakes stop the app.** A provider without a name or capabilities, two providers with
  the same name, or a fallback factory that isn't last, stop the app at start-up with a message
  saying what to change.
- **Your own factory that stores a vendor object,** such as an `Amplitude` or a
  `MixpanelInstance`, needs `@preconcurrency import` of that vendor's module in Swift 6, because
  vendor SDKs aren't marked `Sendable`. Xcode offers the fix.
- **`HeraldCore.Identity`.** Amplitude has an `Identity` type too, so in a file that imports both,
  write the module name in front.
<!-- --8<-- [end:differences] -->

## Documentation

The full documentation is on the [project website](https://mkhytarmkhoian.github.io/herald-docs/).
Its guides describe Herald itself, not one platform, and show the code for iOS, Android and
Flutter. The code on the website comes from [`Samples`](Samples), which CI builds and tests.

See [CHANGELOG.md](CHANGELOG.md) for release notes and [CONTRIBUTING.md](CONTRIBUTING.md) to
contribute.

## License

Apache License 2.0. See [LICENSE](LICENSE).
