import HeraldCore
import HeraldLog

/// The composition root: the one place that knows which vendors the app uses.
///
/// A real app adds its vendors here (`HeraldFirebase`, `HeraldMixpanel` and the rest), each as one
/// more `HeraldProvider`. Nothing else in the app changes.
func makeHerald(timeline: TimelineAnalytics) -> Herald {
    var providers: [HeraldProvider] = []

    #if DEBUG
        let logger: AnalyticsLogger = { message in print(message) }
        let logTracker = LogAnalyticsTrackerService(
            eventTrackerFactory: CompositeLogEventTrackerFactory([
                ScreenViewLogEventTrackerFactory(logger: logger),
                GenericLogEventTrackerFactory(logger: logger),
            ]),
            propertySetterFactory: GenericLogPropertySetterFactory(logger: logger)
        )
        let logService = LogAnalyticsService(logger: logger)
        providers.append(
            HeraldProvider(
                name: "log",
                events: logTracker,
                properties: logTracker,
                identity: logService,
                lifecycle: logService,
                consent: logService
            ))
    #endif

    providers.append(
        HeraldProvider(
            name: "timeline",
            events: timeline,
            properties: timeline,
            identity: timeline,
            lifecycle: timeline,
            consent: timeline
        ))

    return Herald(
        providers: providers,
        errorReporter: { failure in print("analytics: \(failure)") }
    )
}
