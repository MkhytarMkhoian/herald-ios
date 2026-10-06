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

> **In development.** Nothing is released yet.

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

## License

Apache License 2.0. See [LICENSE](LICENSE).
