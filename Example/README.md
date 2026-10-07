# Herald example

A SwiftUI app that sends every Herald call to the log and to an on-screen timeline.

It tracks screen views both ways Herald supports, so you can compare them:

- **Home and Product** use `.trackScreenView` from the optional `HeraldSwiftUI` module. A screen
  view is tracked each time the screen becomes visible, also when the user comes back to it.
- **Settings** tracks its own screen view with plain Herald, from its view model: once each time it
  opens. No extra module.

Product also shows the rest of `HeraldSwiftUI`: an impression for each offer that stays half on
screen for a second, and a tap tracked through `@Environment(\.eventTracker)`. The other events
(added to cart, order paid, consent, sign-in) are tracked the plain way, from the view model that
owns them.

The timeline is a provider of the app's own, `TimelineAnalytics`: implementing Herald's protocols is
all a provider takes. A real app adds its vendors in `HeraldSetup.swift`, and nothing else changes.

Open `HeraldExample.xcodeproj` in Xcode and run it on a simulator. Watch the timeline on the home
screen and the `[herald]` lines in the console. It uses the Herald code in this repository, so it
always shows the current version.

The tests run it too: `ProductModelTests` checks a view model with `FakeAnalyticsProvider`, and
`TimelineUITests` taps through the app and reads the timeline.
