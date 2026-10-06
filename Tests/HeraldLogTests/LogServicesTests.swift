import HeraldCore
import HeraldLog
import HeraldTesting
import Testing

/// The usual setup: screen views, then every other event, and every property.
private func makeTracker(_ logger: @escaping AnalyticsLogger) -> LogAnalyticsTrackerService {
    LogAnalyticsTrackerService(
        eventTrackerFactory: CompositeLogEventTrackerFactory([
            ScreenViewLogEventTrackerFactory(logger: logger),
            GenericLogEventTrackerFactory(logger: logger),
        ]),
        propertySetterFactory: CompositeLogPropertySetterFactory([
            GenericLogPropertySetterFactory(logger: logger)
        ])
    )
}

@Suite struct Services {
    let printed = Printed()

    @Test func lifecycleIdentityAndConsentCallsEachPrintOneLineInOrder() {
        let service = LogAnalyticsService(logger: printed.logger)

        service.start()
        service.setEnabled(true)
        service.identify(Identity(userId: "user-1"))
        service.flush()
        service.reset()
        service.setEnabled(false)

        #expect(
            printed.lines == [
                "[herald] start",
                "[herald] enabled true",
                "[herald] user    user-1",
                "[herald] flush",
                "[herald] reset",
                "[herald] enabled false",
            ])
    }

    @Test func theTrackerServicePrintsWhatItsChainsDecideThroughHerald() {
        let tracker = makeTracker(printed.logger)
        let herald = Herald(providers: [
            HeraldProvider(name: "log", events: tracker, properties: tracker)
        ])

        herald.track(TestScreenView(name: "home"))
        herald.set(TestProperty(name: "plan", value: .string("pro")))

        #expect(printed.lines == ["[herald] screen  home", "[herald] prop    plan = pro"])
    }

    @Test func anUnclaimedEventOrPropertyIsIgnoredByAChainWithoutAFallback() {
        let tracker = LogAnalyticsTrackerService(
            eventTrackerFactory: CompositeLogEventTrackerFactory([
                ScreenViewLogEventTrackerFactory(logger: printed.logger)
            ]),
            propertySetterFactory: CompositeLogPropertySetterFactory([])
        )

        tracker.track(TestEvent(name: "ignored"))
        tracker.set(TestProperty(name: "ignored", value: .int(1)))

        #expect(printed.lines.isEmpty)
    }

    @Test func theTrackersOfOneEventRunInOrderAndAFailureStopsTheRestAndIsReported() {
        let failures = ReportedFailures()
        let tracker = LogAnalyticsTrackerService(
            eventTrackerFactory: ClaimingLogEventTrackerFactory(
                name: "e", steps: [.print("first"), .fail, .print("third")],
                logger: printed.logger),
            propertySetterFactory: CompositeLogPropertySetterFactory([])
        )
        let herald = Herald(
            providers: [HeraldProvider(name: "log", events: tracker)],
            errorReporter: { failure in failures.append(failure) }
        )

        herald.track(TestEvent(name: "e"))

        #expect(printed.lines == ["first"])
        #expect(failures.all.map { failure in "\(failure.operation)" } == ["Track(e)"])
    }

    @Test func anUnmappedEventIsReportedThroughHerald() throws {
        let failures = ReportedFailures()
        let tracker = LogAnalyticsTrackerService(
            eventTrackerFactory: CompositeLogEventTrackerFactory([
                ScreenViewLogEventTrackerFactory(logger: printed.logger),
                RequireMappedLogEventTrackerFactory(),
            ]),
            propertySetterFactory: RequireMappedLogPropertySetterFactory()
        )
        let herald = Herald(
            providers: [HeraldProvider(name: "log", events: tracker, properties: tracker)],
            errorReporter: { failure in failures.append(failure) }
        )

        herald.track(TestEvent(name: "checkout_started"))
        herald.set(TestProperty(name: "plan", value: .string("pro")))

        #expect(failures.all.count == 2)
        let eventFailure = try #require(failures.all.first)
        #expect(eventFailure.error is UnhandledEventError)
        #expect(failures.all.last?.error is UnhandledPropertyError)
    }
}
