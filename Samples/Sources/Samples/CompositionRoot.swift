import AdjustSdk
import AmplitudeSwift
import HeraldAdjust
import HeraldAmplitude
import HeraldCore
import HeraldFirebase
import HeraldMixpanel
import Mixpanel

// --8<-- [start:firebase-provider]
func firebaseProvider() -> HeraldProvider {
    let tracker = FirebaseAnalyticsTrackerService(
        eventTrackerFactory: CompositeFirebaseEventTrackerFactory([
            ScreenViewFirebaseEventTrackerFactory(),  // GA4's reserved screen_view
            GenericFirebaseEventTrackerFactory(),  // everything else, as-is
        ]),
        propertySetterFactory: GenericFirebasePropertySetterFactory()
    )
    let service = FirebaseAnalyticsService()
    return HeraldProvider(
        name: "firebase",
        events: tracker,
        properties: tracker,
        identity: service,
        lifecycle: service,
        consent: service
    )
}
// --8<-- [end:firebase-provider]

func mixpanelProvider(mixpanel: MixpanelInstance) -> HeraldProvider {
    let tracker = MixpanelAnalyticsTrackerService(
        eventTrackerFactory: CompositeMixpanelEventTrackerFactory([
            ScreenViewMixpanelEventTrackerFactory(mixpanel: mixpanel),
            GenericMixpanelEventTrackerFactory(mixpanel: mixpanel),
        ]),
        propertySetterFactory: CompositeMixpanelPropertySetterFactory([
            UserPropertyMixpanelPropertySetterFactory(mixpanel: mixpanel),  // before the generic
            GenericMixpanelPropertySetterFactory(mixpanel: mixpanel),
        ])
    )
    let service = MixpanelAnalyticsService(mixpanel: mixpanel)
    return HeraldProvider(
        name: "mixpanel",
        events: tracker,
        properties: tracker,
        identity: service,
        lifecycle: service,
        consent: service
    )
}

func adjustProvider(config: ADJConfig, tokens: [String: String]) -> HeraldProvider {
    let tracker = AdjustAnalyticsTrackerService(
        eventTrackerFactory: TokenAdjustEventTrackerFactory(tokens: tokens),  // tokened events only
        propertySetterFactory: GenericAdjustPropertySetterFactory()
    )
    let service = AdjustAnalyticsService(config: config)
    return HeraldProvider(
        name: "adjust",
        events: tracker,
        properties: tracker,
        identity: service,
        lifecycle: service,
        consent: service
    )
}

func amplitudeProvider(amplitude: Amplitude) -> HeraldProvider {
    let tracker = AmplitudeAnalyticsTrackerService(
        eventTrackerFactory: CompositeAmplitudeEventTrackerFactory([
            ScreenViewAmplitudeEventTrackerFactory(amplitude: amplitude),
            GenericAmplitudeEventTrackerFactory(amplitude: amplitude),
        ]),
        propertySetterFactory: GenericAmplitudePropertySetterFactory(amplitude: amplitude)
    )
    let service = AmplitudeAnalyticsService(amplitude: amplitude)
    return HeraldProvider(
        name: "amplitude",
        events: tracker,
        properties: tracker,
        identity: service,
        lifecycle: service,
        consent: service
    )
}

func buildHerald(
    mixpanel: MixpanelInstance, adjustConfig: ADJConfig, adjustTokens: [String: String]
) -> Herald {
    // --8<-- [start:herald]
    let herald = Herald(
        providers: [
            firebaseProvider(),
            mixpanelProvider(mixpanel: mixpanel),
            adjustProvider(config: adjustConfig, tokens: adjustTokens),
        ],
        errorReporter: { failure in print("analytics: \(failure)") }
    )
    // --8<-- [end:herald]
    return herald
}

// --8<-- [start:start-from-main]
func startAnalytics(
    herald: Herald,
    consentRepository: any AnalyticsConsentRepository  // however you store the answer
) {
    herald.start()  // some vendors start quiet here
    herald.setEnabled(consentRepository.isEnabled())  // so re-apply the stored answer
}
// --8<-- [end:start-from-main]
