import HeraldCore
import HeraldTesting
import Testing

@Suite struct Records {
    let analytics = FakeAnalyticsProvider()

    @Test func everyCallGoesIntoOneListInOrder() {
        analytics.start()
        analytics.identify(Identity(userId: "user-1"))
        analytics.set(TestProperty(name: "plan", value: .string("pro")))
        analytics.track(TestEvent(name: "checkout_started"))
        analytics.setEnabled(false)
        analytics.flush()
        analytics.reset()

        #expect(
            analytics.records == [
                .started,
                .identified(Identity(userId: "user-1")),
                .propertySet(TestProperty(name: "plan", value: .string("pro"))),
                .tracked(TestEvent(name: "checkout_started")),
                .enabledSet(false),
                .flushed,
                .reset,
            ])
    }

    @Test func recordsAreEqualByKindAndContent() {
        #expect(AnalyticsRecord.tracked(TestEvent(name: "a")) == .tracked(TestEvent(name: "a")))
        #expect(
            AnalyticsRecord.tracked(TestEvent(name: "a", parameters: ["n": .int(1)]))
                != .tracked(TestEvent(name: "a", parameters: ["n": .string("1")])))
        #expect(AnalyticsRecord.enabledSet(true) != .enabledSet(false))
        #expect(AnalyticsRecord.started != .flushed)
    }

    @Test func recordsPrintAsTheLinesAFailureShows() {
        let event = TestEvent(name: "e", parameters: ["zulu": .string("z"), "alpha": .int(1)])

        #expect("\(AnalyticsRecord.tracked(event))" == "event    e { alpha = 1, zulu = z }")
        #expect(
            "\(AnalyticsRecord.propertySet(TestProperty(name: "plan", value: .string("pro"))))"
                == "property plan = pro")
        #expect("\(AnalyticsRecord.enabledSet(true))" == "enabled  true")
    }

    @Test func aListOfRecordsStaysAsItWasWhenRead() {
        analytics.track(TestEvent(name: "first"))
        let snapshot = analytics.records
        analytics.track(TestEvent(name: "second"))

        #expect(snapshot.count == 1)
        #expect(analytics.records.count == 2)
    }

    @Test func clearForgetsTheRecordsAndWhatWasAlreadyAsserted() {
        analytics.track(TestEvent(name: "checkout_started"))
        analytics.assertTracked("checkout_started")

        analytics.clear()

        analytics.assertNothingTracked()
        analytics.assertNothingElseTracked()
    }
}

@Suite struct PassingAssertions {
    let analytics = FakeAnalyticsProvider()

    @Test func assertTrackedComparesParametersByTypeNotByTheirText() {
        analytics.track(
            TestEvent(
                name: "checkout_started",
                parameters: [
                    "plan": .string("pro"), "seats": .int(3), "price": .double(3.5),
                    "trial": .bool(false),
                ]))

        analytics.assertTracked("checkout_started") { event in
            event.param("plan", "pro")
            event.param("seats", 3)
            event.param("price", 3.5)
            event.param("trial", false)
            event.param("seats", .int(3))
        }
    }

    @Test func theTrackedEventItselfIsThereForCustomChecks() {
        analytics.track(TestEvent(name: "checkout_started"))

        analytics.assertTracked("checkout_started") { event in
            #expect(event.event is TestEvent)
        }
    }

    @Test func noParametersPassesOnAnEventWithoutParameters() {
        analytics.track(TestEvent(name: "checkout_started"))

        analytics.assertTracked("checkout_started") { event in
            event.noParameters()
        }
    }

    @Test func assertNotTrackedPassesWhenTheEventIsMissing() {
        analytics.track(TestEvent(name: "cart_viewed"))

        analytics.assertNotTracked("checkout_started")
    }

    @Test func assertTrackedTimesAcceptsZero() {
        analytics.track(TestEvent(name: "cart_viewed"))

        analytics.assertTrackedTimes("checkout_started", 0)
    }

    @Test func eventAssertionsIgnoreCallsThatAreNotEvents() {
        analytics.start()
        analytics.set(TestProperty(name: "plan", value: .string("pro")))
        analytics.identify(Identity(userId: "user-1"))

        analytics.assertNothingTracked()
        analytics.assertNothingElseTracked()
    }

    @Test func assertPropertySetChecksTheLastValueByType() {
        analytics.set(TestProperty(name: "plan", value: .string("free")))
        analytics.set(TestProperty(name: "plan", value: .string("pro")))
        analytics.set(TestProperty(name: "seats", value: .int(3)))

        analytics.assertPropertySet("plan", "pro")
        analytics.assertPropertySet("seats", 3)
        analytics.assertPropertySet("seats", .int(3))
    }

    @Test func assertIdentifiedPassesEvenAfterALaterReset() {
        analytics.identify(Identity(userId: "user-1"))
        analytics.reset()

        analytics.assertIdentified("user-1")
    }
}

/// Keeps `debug_ping` away from `inner`.
private struct ExceptDebugPing: EventTrackerService {
    let inner: any EventTrackerService

    func track(_ event: any Event) {
        if event.name != "debug_ping" {
            inner.track(event)
        }
    }
}

/// The fake as a real provider, so the test runs through a real `Herald`.
@Suite struct InHerald {
    let analytics = FakeAnalyticsProvider()

    @Test func anEventTrackedThroughHeraldReachesTheFake() {
        let herald = Herald(providers: [
            HeraldProvider(name: "test", events: analytics, properties: analytics)
        ])

        herald.track(TestEvent(name: "checkout_started", parameters: ["plan": .string("pro")]))

        analytics.assertTracked("checkout_started") { event in
            event.param("plan", "pro")
        }
        analytics.assertNothingElseTracked()
    }

    @Test func aDecoratorShowsInWhatTheFakeDidNotGet() {
        let herald = Herald(providers: [
            HeraldProvider(name: "test", events: ExceptDebugPing(inner: analytics))
        ])

        herald.track(TestEvent(name: "checkout_started"))
        herald.track(TestEvent(name: "debug_ping"))

        analytics.assertTracked("checkout_started")
        analytics.assertNotTracked("debug_ping")
        analytics.assertNothingElseTracked()
    }
}
