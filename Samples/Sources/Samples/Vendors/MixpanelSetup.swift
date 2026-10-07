import HeraldCore
import HeraldMixpanel
import Mixpanel

func mixpanelProvider(projectToken: String) -> HeraldProvider {
    // --8<-- [start:provider]
    let mixpanel = Mixpanel.initialize(
        token: projectToken,
        trackAutomaticEvents: false,
        optOutTrackingByDefault: true  // silent until consent
    )

    let tracker = MixpanelAnalyticsTrackerService(
        eventTrackerFactory: CompositeMixpanelEventTrackerFactory([
            ScreenViewMixpanelEventTrackerFactory(mixpanel: mixpanel),
            GenericMixpanelEventTrackerFactory(mixpanel: mixpanel),
        ]),
        propertySetterFactory: CompositeMixpanelPropertySetterFactory([
            UserPropertyMixpanelPropertySetterFactory(mixpanel: mixpanel),  // the profile: first
            GenericMixpanelPropertySetterFactory(mixpanel: mixpanel),  // super properties
        ])
    )
    let service = MixpanelAnalyticsService(mixpanel: mixpanel)

    let provider = HeraldProvider(
        name: "mixpanel",
        events: tracker,
        properties: tracker,
        identity: service,
        lifecycle: service,
        consent: service
    )
    // --8<-- [end:provider]
    return provider
}
