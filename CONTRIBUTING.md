# Contributing

Thanks for helping with Herald. This page explains how to get a change ready to become part of the
iOS SDK.

Herald's design is shared with the [Android](https://github.com/MkhytarMkhoian/herald) and
[Flutter](https://github.com/MkhytarMkhoian/herald-flutter) SDKs. A change to how Herald behaves,
such as the factory chain, the fan-out or a vendor's consent rules, belongs in all three, so open
an issue first.

## Setting up

Herald for iOS is six Swift packages: this one, with `HeraldCore`, `HeraldLog` and
`HeraldTesting`, and one package per vendor, each in its own repository. Clone them next to each
other:

```bash
for repo in herald-ios herald-ios-firebase herald-ios-mixpanel herald-ios-amplitude \
    herald-ios-adjust herald-ios-appsflyer; do
  git clone "https://github.com/MkhytarMkhoian/$repo"
done
```

They need Xcode 16 or newer.

```bash
swift build
swift test                      # the modules that also build for macOS
swift format lint --strict -r Sources Tests Samples/Sources Samples/Tests Package.swift
```

The samples build for iOS only, in the Simulator:

```bash
cd Samples && xcodebuild test -scheme herald-ios-samples-Package \
    -destination "id=$(../scripts/simulator.sh)"
```

To try your change in an app, add your checkout as a local package: in Xcode, File → Add Package
Dependencies → Add Local.

## What every change needs

- **Plain Swift.** Prefer what a reader new to Swift can follow: structs, protocols, enums,
  `if`/`switch` and `for` loops. A newer or fancier feature needs a reason that's worth more than
  the time it takes to learn it.
- **Code that matches its surroundings.** Run `swift format -i -r Sources Tests Package.swift`
  (100 columns). Use the same naming and the same amount of comments as the code around your
  change.
- **Few comments, in simple words.** Document what a reader can't guess from the name: a vendor
  rule, a gotcha, why an order matters.
- **Core knows no vendor.** `HeraldCore` never names a vendor, in code, docs or examples.
- **Throw instead of quietly fixing data.** Inside a vendor module, refuse bad input by throwing.
  The vendor's public methods catch it and pass it to `Herald.reportFailure`, so the app's error
  reporter sees it.
- **The website's samples,** when users would notice. The code on the website comes from
  [`Samples`](Samples), a package of its own that uses `herald-ios` and every vendor package from
  the folders next to it. CI builds and tests it. The website shows each `// --8<--` section and
  the marked sections of `README.md` by name, so keep those names, or rename them on the website
  in step.
- **Tests** with Swift Testing, named in plain words, such as `aFailingVendorIsReported`.
- **A line in `CHANGELOG.md`** under the next, unreleased version, starting with `New:`, `Fix:`,
  `Upgrade:` or `Breaking:`.
