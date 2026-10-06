import HeraldCore
import HeraldTesting
import Testing

/// Every assertion must fail when it should, and say why.
@Suite struct Failures {
    let analytics = FakeAnalyticsProvider()

    @Test func assertTrackedFailsForAMissingEventAndShowsWhatWasTracked() {
        analytics.track(TestEvent(name: "cart_viewed"))

        let message = failureMessage { analytics.assertTracked("checkout_started") }

        #expect(message.contains("checkout_started"))
        #expect(message.contains("cart_viewed"))
    }

    @Test func assertTrackedFailsForADuplicateAndPointsToAssertTrackedTimes() {
        analytics.track(TestEvent(name: "checkout_started"))
        analytics.track(TestEvent(name: "checkout_started"))

        let message = failureMessage { analytics.assertTracked("checkout_started") }

        #expect(message.contains("2 were tracked"))
        #expect(message.contains("assertTrackedTimes"))
    }

    @Test func paramFailsForAMissingParameter() {
        analytics.track(TestEvent(name: "checkout_started", parameters: ["plan": .string("pro")]))

        let message = failureMessage {
            analytics.assertTracked("checkout_started") { event in event.param("seats", 3) }
        }

        #expect(message.contains("no parameter 'seats'"))
    }

    @Test func paramFailsWhenANumberWasSentAsText() {
        analytics.track(TestEvent(name: "checkout_started", parameters: ["seats": .string("3")]))

        let message = failureMessage {
            analytics.assertTracked("checkout_started") { event in event.param("seats", 3) }
        }

        #expect(message.contains("was string(\"3\"), expected int(3)"))
    }

    @Test func noParametersFailsForAnEventWithParameters() {
        analytics.track(TestEvent(name: "checkout_started", parameters: ["plan": .string("pro")]))

        let message = failureMessage {
            analytics.assertTracked("checkout_started") { event in event.noParameters() }
        }

        #expect(message.contains("plan"))
    }

    @Test func assertNothingElseTrackedFailsForAnEventNobodyChecked() {
        analytics.track(TestEvent(name: "checkout_started"))
        analytics.track(TestEvent(name: "debug_ping"))
        analytics.assertTracked("checkout_started")

        let message = failureMessage { analytics.assertNothingElseTracked() }

        #expect(message.contains("Unexpected events tracked: debug_ping."))
    }

    @Test func assertNothingElseTrackedPassesOnceEveryEventWasChecked() {
        analytics.track(TestEvent(name: "checkout_started"))
        analytics.track(TestEvent(name: "cart_viewed"))
        analytics.track(TestEvent(name: "cart_viewed"))

        analytics.assertTracked("checkout_started")
        analytics.assertTrackedTimes("cart_viewed", 2)
        analytics.assertNothingElseTracked()
    }

    @Test func assertTrackedTimesFailsForTheWrongCount() {
        analytics.track(TestEvent(name: "checkout_started"))

        let message = failureMessage { analytics.assertTrackedTimes("checkout_started", 2) }

        #expect(message.contains("tracked 2 times, but it was tracked 1 times"))
    }

    @Test func assertNotTrackedAndAssertNothingTrackedFailWhenSomethingWasTracked() {
        analytics.track(TestEvent(name: "checkout_started"))

        _ = failureMessage { analytics.assertNotTracked("checkout_started") }
        _ = failureMessage { analytics.assertNothingTracked() }
    }

    @Test func assertPropertySetFailsWhenTheRightValueWasOverwrittenAndShowsBoth() {
        analytics.set(TestProperty(name: "plan", value: .string("pro")))
        analytics.set(TestProperty(name: "plan", value: .string("free")))

        let message = failureMessage { analytics.assertPropertySet("plan", "pro") }

        #expect(message.contains("string(\"pro\") then string(\"free\")"))
    }

    @Test func assertPropertySetFailsWhenANumberWasSetAsText() {
        analytics.set(TestProperty(name: "seats", value: .string("3")))

        let message = failureMessage { analytics.assertPropertySet("seats", 3) }

        #expect(message.contains("to be int(3), but it was set to string(\"3\")"))
    }

    @Test func assertPropertySetFailsForAPropertyThatWasNeverSet() {
        analytics.set(TestProperty(name: "plan", value: .string("pro")))

        let message = failureMessage { analytics.assertPropertySet("total_purchases", 42) }

        #expect(message.contains("never was"))
        #expect(message.contains("plan"))
    }

    @Test func assertIdentifiedFailsForAnotherUser() {
        analytics.identify(Identity(userId: "user-2"))

        let message = failureMessage { analytics.assertIdentified("user-1") }

        #expect(message.contains("user-1"))
        #expect(message.contains("user-2"))
    }

    @Test func aFailureListsEveryKindOfCallInOrder() throws {
        analytics.start()
        analytics.identify(Identity(userId: "user-1"))
        analytics.set(TestProperty(name: "plan", value: .string("pro")))
        analytics.track(TestEvent(name: "cart_viewed", parameters: ["items": .int(2)]))
        analytics.setEnabled(false)
        analytics.flush()
        analytics.reset()

        let message = failureMessage { analytics.assertTracked("checkout_started") }

        let recorded = try #require(message.components(separatedBy: "Recorded:\n").last)
        #expect(
            recorded == """
                  1. start
                  2. identify user-1
                  3. property plan = pro
                  4. event    cart_viewed { items = 2 }
                  5. enabled  false
                  6. flush
                  7. reset
                """)
    }

    @Test func aFailureWithNothingRecordedSaysSo() {
        let message = failureMessage { analytics.assertTracked("checkout_started") }

        #expect(message.contains("nothing was recorded"))
    }
}
