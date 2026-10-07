import AppsFlyerLib
import HeraldAppsFlyer
import HeraldCore

func setUpAppsFlyer() {
    // --8<-- [start:init]
    AppsFlyerLib.shared().initialize(devKey: "YOUR_DEV_KEY", appId: "YOUR_APPLE_APP_ID")
    // AppsFlyer 7 sends a session only on start(), once per foreground. While Herald keeps the SDK
    // stopped, before consent, it sends nothing.
    AppsFlyerLib.shared().registerSessionReadyListener {
        AppsFlyerLib.shared().start()
    }
    // --8<-- [end:init]
}

func appsFlyerProvider(featureFactories: [any AppsFlyerEventTrackerFactory]) -> HeraldProvider {
    // --8<-- [start:provider]
    let tracker = AppsFlyerAnalyticsTrackerService(
        // Your conversions and revenue. Nothing at the end, so other events aren't sent.
        eventTrackerFactory: CompositeAppsFlyerEventTrackerFactory(featureFactories)
    )
    let service = AppsFlyerAnalyticsService()  // uses AppsFlyerLib.shared(), set up at start-up

    let provider = HeraldProvider(
        name: "appsflyer",
        events: tracker,  // no properties: AppsFlyer keeps no user attributes
        identity: service,
        lifecycle: service,
        consent: service
    )
    // --8<-- [end:provider]
    return provider
}
