import AmplitudeSwift
import HeraldAmplitude
import HeraldCore

func amplitudeProvider(apiKey: String) -> HeraldProvider {
    // --8<-- [start:provider]
    // Herald sends screen views, so leave .screenViews out of autocapture, as by default.
    let amplitude = Amplitude(
        configuration: Configuration(apiKey: apiKey, optOut: true))  // silent until consent

    let tracker = AmplitudeAnalyticsTrackerService(
        eventTrackerFactory: CompositeAmplitudeEventTrackerFactory([
            ScreenViewAmplitudeEventTrackerFactory(amplitude: amplitude),
            GenericAmplitudeEventTrackerFactory(amplitude: amplitude),
        ]),
        propertySetterFactory: GenericAmplitudePropertySetterFactory(amplitude: amplitude)
    )
    let service = AmplitudeAnalyticsService(amplitude: amplitude)

    let provider = HeraldProvider(
        name: "amplitude",
        events: tracker,
        properties: tracker,
        identity: service,
        lifecycle: service,
        consent: service
    )
    // --8<-- [end:provider]
    return provider
}
