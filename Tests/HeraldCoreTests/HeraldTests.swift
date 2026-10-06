import Dispatch
import Foundation
import HeraldCore
import Testing

private let event = TestEvent(name: "an_event")
private let property = TestProperty(name: "a_property", value: .string("pro"))
private let identity = Identity(userId: "user-1")

/// A provider with every capability, and one that only takes events.
private func makeHerald(
    analytics: RecordingService,
    attribution: RecordingService,
    failures: SharedList<AnalyticsFailure>
) -> Herald {
    Herald(
        providers: [
            HeraldProvider(
                name: "analytics",
                events: analytics,
                properties: analytics,
                identity: analytics,
                lifecycle: analytics,
                consent: analytics
            ),
            HeraldProvider(name: "attribution", events: attribution),
        ],
        errorReporter: { failure in failures.append(failure) }
    )
}

@Suite struct Calls {
    let analytics = RecordingService()
    let attribution = RecordingService()
    let herald: Herald

    init() {
        herald = makeHerald(analytics: analytics, attribution: attribution, failures: SharedList())
    }

    @Test func trackReachesEveryProviderThatTakesEvents() {
        herald.track(event)

        #expect(analytics.received == ["track an_event"])
        #expect(attribution.received == ["track an_event"])
    }

    @Test func setSkipsAProviderWithoutProperties() {
        herald.set(property)

        #expect(analytics.received == ["set a_property"])
        #expect(attribution.received.isEmpty)
    }

    @Test func identifyAndResetReachOnlyProvidersWithIdentity() {
        herald.identify(identity)
        herald.reset()

        #expect(analytics.received == ["identify user-1", "reset"])
        #expect(attribution.received.isEmpty)
    }

    @Test func startAndFlushReachOnlyProvidersWithALifecycle() {
        herald.start()
        herald.flush()

        #expect(analytics.received == ["start", "flush"])
        #expect(attribution.received.isEmpty)
    }

    @Test func setEnabledReachesOnlyProvidersWithConsent() {
        herald.setEnabled(true)

        #expect(analytics.received == ["enabled true"])
        #expect(attribution.received.isEmpty)
    }

    @Test func aProviderWithOnlyConsentIsCalled() {
        let herald = Herald(providers: [HeraldProvider(name: "analytics", consent: analytics)])

        herald.setEnabled(false)

        #expect(analytics.received == ["enabled false"])
    }

    @Test func aDecoratorKeepsAnEventFromOneProviderOnly() {
        let attribution = attribution
        let herald = Herald(providers: [
            HeraldProvider(name: "analytics", events: analytics),
            HeraldProvider(
                name: "attribution",
                events: TestEventTracker { event in
                    if event.name != "an_event" {
                        attribution.track(event)
                    }
                }
            ),
        ])

        herald.track(event)

        #expect(analytics.received == ["track an_event"])
        #expect(attribution.received.isEmpty)
    }

    @Test func callsReachEveryVendorInTheOrderTheyWereMade() {
        let log = SharedList<String>()
        let first = RecordingService(log: log)
        let second = RecordingService(log: log)
        let herald = Herald(providers: [
            HeraldProvider(name: "first", events: first, consent: first),
            HeraldProvider(name: "second", events: second, consent: second),
        ])

        herald.setEnabled(false)
        herald.track(event)

        #expect(log.all == ["enabled false", "enabled false", "track an_event", "track an_event"])
    }

    @Test func callsFromManyThreadsAtOnceReportEachFailureAgainstItsOwnVendor() {
        let failures = SharedList<AnalyticsFailure>()
        let herald = Herald(
            providers: [
                HeraldProvider(
                    name: "failing", events: RecordingService(failure: TestError(message: "down"))),
                HeraldProvider(name: "working", events: RecordingService()),
            ],
            errorReporter: { failure in failures.append(failure) }
        )

        DispatchQueue.concurrentPerform(iterations: 100) { number in
            herald.track(TestEvent(name: "event_\(number)"))
        }

        #expect(failures.all.count == 100)
        #expect(failures.all.allSatisfy { failure in failure.provider == "failing" })
    }
}

@Suite struct Failures {
    let analytics = RecordingService(failure: TestError(message: "analytics is down"))
    let attribution = RecordingService()
    let failures = SharedList<AnalyticsFailure>()
    let herald: Herald

    init() {
        herald = makeHerald(analytics: analytics, attribution: attribution, failures: failures)
    }

    @Test func aFailingVendorDoesNotStopTheOthersAndIsReported() throws {
        herald.track(event)

        #expect(attribution.received == ["track an_event"])
        let failure = try #require(failures.all.first)
        #expect(failures.all.count == 1)
        #expect(failure.provider == "analytics")
        #expect(failure.operation == .track(eventName: "an_event"))
        #expect(failure.error as? TestError == TestError(message: "analytics is down"))
    }

    @Test func theReportNamesTheEventThatFailed() {
        herald.track(TestEvent(name: "other_event"))

        #expect(
            failures.all.map { failure in failure.operation } == [.track(eventName: "other_event")])
    }

    @Test func theReportNamesThePropertyThatFailed() {
        herald.set(property)

        #expect(
            failures.all.map { failure in failure.operation } == [
                .setProperty(propertyName: "a_property")
            ])
    }

    @Test func failuresAreReportedInRegistrationOrder() {
        let herald = Herald(
            providers: [
                HeraldProvider(
                    name: "first", events: RecordingService(failure: TestError(message: "1"))),
                HeraldProvider(
                    name: "second", events: RecordingService(failure: TestError(message: "2"))),
            ],
            errorReporter: { failure in failures.append(failure) }
        )

        herald.track(event)

        #expect(failures.all.map { failure in failure.provider } == ["first", "second"])
    }

    @Test func everyFailureAVendorReportsDuringOneCallIsReported() {
        let herald = Herald(
            providers: [
                HeraldProvider(
                    name: "analytics",
                    events: TestEventTracker { _ in
                        Herald.reportFailure(TestError(message: "1"))
                        Herald.reportFailure(TestError(message: "2"))
                    }
                )
            ],
            errorReporter: { failure in failures.append(failure) }
        )

        herald.track(event)

        let errors = failures.all.map { failure in failure.error as? TestError }
        #expect(errors == [TestError(message: "1"), TestError(message: "2")])
    }

    @Test func aFailureReportedFromATaskTheVendorStartedNamesItsVendorAndCall() async throws {
        let herald = Herald(
            providers: [
                HeraldProvider(
                    name: "analytics",
                    events: TestEventTracker { _ in
                        Task {
                            Herald.reportFailure(TestError(message: "later"))
                        }
                    }
                )
            ],
            errorReporter: { failure in failures.append(failure) }
        )

        herald.track(event)
        // The task runs some time after `track` returns.
        for _ in 0..<500 where failures.all.isEmpty {
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        let failure = try #require(failures.all.first)
        #expect(failure.provider == "analytics")
        #expect(failure.operation == .track(eventName: "an_event"))
    }

    @Test func withoutAReporterFailuresAreDropped() {
        let herald = Herald(providers: [HeraldProvider(name: "analytics", events: analytics)])

        herald.track(event)

        #expect(analytics.received == ["track an_event"])
    }

    // Tests that check the app stops run in a separate process, which only macOS allows.
    #if os(macOS)
        @Test func aFailureReportedOutsideAHeraldCallStopsADebugBuild() async {
            await #expect(processExitsWith: .failure) {
                Herald.reportFailure(TestError(message: "too late"))
            }
        }

        @Test func aFailureReportedFromAnotherQueueStopsADebugBuild() async {
            await #expect(processExitsWith: .failure) {
                let herald = Herald(providers: [
                    HeraldProvider(
                        name: "late",
                        events: TestEventTracker { _ in
                            // Work on another queue doesn't see the call Herald is making.
                            DispatchQueue.global().async {
                                Herald.reportFailure(TestError(message: "too late"))
                            }
                        }
                    )
                ])
                herald.track(TestEvent(name: "an_event"))
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    #endif
}

#if os(macOS)
    @Suite struct Setup {
        @Test func aProviderWithoutCapabilitiesIsRefused() async throws {
            let result = await #expect(
                processExitsWith: .failure, observing: [\.standardErrorContent]
            ) {
                _ = HeraldProvider(name: "empty")
            }
            let message = String(decoding: try #require(result).standardErrorContent, as: UTF8.self)
            #expect(message.contains("no capabilities"))
        }

        @Test func aProviderWithABlankNameIsRefused() async {
            await #expect(processExitsWith: .failure) {
                _ = HeraldProvider(name: " ", events: RecordingService())
            }
        }

        @Test func twoProvidersWithTheSameNameAreRefused() async throws {
            let result = await #expect(
                processExitsWith: .failure, observing: [\.standardErrorContent]
            ) {
                _ = Herald(providers: [
                    HeraldProvider(name: "analytics", events: RecordingService()),
                    HeraldProvider(name: "analytics", events: RecordingService()),
                ])
            }
            let message = String(decoding: try #require(result).standardErrorContent, as: UTF8.self)
            #expect(message.contains("named 'analytics'"))
        }
    }
#endif
