import AdjustSdk
import HeraldAdjust
import HeraldCore

func adjustProvider(featureFactories: [any AdjustEventTrackerFactory]) -> HeraldProvider? {
    // --8<-- [start:provider]
    // Adjust returns nil for a config it can't use, such as one without an app token.
    guard let config = ADJConfig(appToken: "YOUR_APP_TOKEN", environment: ADJEnvironmentProduction)
    else {
        return nil
    }

    let tracker = AdjustAnalyticsTrackerService(
        eventTrackerFactory: CompositeAdjustEventTrackerFactory(
            featureFactories + [  // revenue and custom mappings first
                TokenAdjustEventTrackerFactory(tokens: ["checkout_completed": "abc123"])
            ]),  // nothing at the end: only tokened events are sent
        propertySetterFactory: GenericAdjustPropertySetterFactory()
    )
    // Starts Adjust itself, silent until consent. Don't call Adjust.initSdk yourself.
    let service = AdjustAnalyticsService(config: config)

    let provider = HeraldProvider(
        name: "adjust",
        events: tracker,
        properties: tracker,
        identity: service,
        lifecycle: service,
        consent: service
    )
    // --8<-- [end:provider]
    return provider
}
