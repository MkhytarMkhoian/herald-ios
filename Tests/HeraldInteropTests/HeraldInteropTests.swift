import Foundation
import HeraldCore
import HeraldTesting
import Testing

@testable import HeraldInterop

// Stand-ins for what Kotlin exports: a label is an Objective-C protocol, and an event is an object
// that conforms to it.
@objc private protocol PersonalDataLabel {}
private final class KotlinProfileOpened: NSObject, PersonalDataLabel {}
private final class KotlinCheckoutStarted: NSObject {}

@Suite struct HeraldInteropTests {
    private let analytics = FakeAnalyticsProvider()

    private func bridge(
        translate: HeraldBridge.Translation? = nil, errorReporter: AnalyticsErrorReporter? = nil
    ) -> HeraldBridge {
        HeraldBridge(
            Herald(providers: [
                HeraldProvider(
                    name: "fake", events: analytics, properties: analytics, identity: analytics,
                    lifecycle: analytics, consent: analytics)
            ]),
            translate: translate, errorReporter: errorReporter)
    }

    @Test func anEventKeepsItsNameAndTypedParameters() {
        bridge().track(
            name: "checkout_started",
            parameters: [
                "plan": .string("pro"), "seats": .int(3), "price": .double(9.5),
                "trial": .bool(true),
            ],
            isScreenView: false, needsTranslation: false, kotlinEvent: KotlinCheckoutStarted())

        analytics.assertTracked("checkout_started") { event in
            event.param("plan", "pro")
            event.param("seats", 3)
            event.param("price", 9.5)
            event.param("trial", true)
        }
    }

    @Test func aScreenViewBecomesAScreenViewEvent() {
        bridge().track(
            name: "home", parameters: [:], isScreenView: true, needsTranslation: false,
            kotlinEvent: KotlinCheckoutStarted())

        #expect(analytics.events.first is any ScreenViewEvent)
    }

    @Test func theKotlinEventKeepsItsLabels() {
        bridge().track(
            name: "profile_opened", parameters: [:], isScreenView: false, needsTranslation: false,
            kotlinEvent: KotlinProfileOpened())
        bridge().track(
            name: "checkout_started", parameters: [:], isScreenView: false, needsTranslation: false,
            kotlinEvent: KotlinCheckoutStarted())

        #expect(analytics.events[0].kotlinEvent is PersonalDataLabel)
        #expect(!(analytics.events[1].kotlinEvent is PersonalDataLabel))
    }

    @Test func aScreenViewKeepsItsKotlinEventToo() {
        bridge().track(
            name: "profile", parameters: [:], isScreenView: true, needsTranslation: false,
            kotlinEvent: KotlinProfileOpened()
        )

        #expect(analytics.events.first?.kotlinEvent is PersonalDataLabel)
    }

    @Test func anEventFromSwiftHasNoKotlinEvent() {
        struct SwiftEvent: Event {
            var name: String { "swift_event" }
        }

        #expect(SwiftEvent().kotlinEvent == nil)
    }

    @Test func aTranslatedEventIsTrackedInsteadOfAPlainOne() {
        struct Purchase: Event, Equatable {
            let price: Double
            let parameters: [String: AnalyticsValue]
            var name: String { "purchase" }
        }
        let bridge = bridge { kotlinEvent, parameters in
            kotlinEvent is KotlinProfileOpened ? Purchase(price: 4.99, parameters: parameters) : nil
        }

        bridge.track(
            name: "profile_opened", parameters: ["plan": .string("pro")], isScreenView: false,
            needsTranslation: true, kotlinEvent: KotlinProfileOpened())
        bridge.track(
            name: "checkout_started", parameters: [:], isScreenView: false,
            needsTranslation: false, kotlinEvent: KotlinCheckoutStarted())

        #expect(
            analytics.events[0] as? Purchase
                == Purchase(price: 4.99, parameters: ["plan": .string("pro")]))
        #expect(analytics.events[1] is BridgedEvent)
    }

    @Test func anUntranslatedVendorEventIsReportedAndTrackedAsAPlainEvent() {
        let failures = Failures()
        let bridge = bridge(translate: { _, _ in nil }, errorReporter: failures.add)

        bridge.track(
            name: "purchase", parameters: [:], isScreenView: false, needsTranslation: true,
            kotlinEvent: KotlinProfileOpened())

        #expect(failures.all.map { failure in "\(failure.operation)" } == ["Track(purchase)"])
        #expect("\(failures.all[0].error)".contains("has no translation"))
        #expect(analytics.events.first is BridgedEvent)
    }

    @Test func aPlainEventWithoutATranslationIsNotReported() {
        let failures = Failures()
        let bridge = bridge(translate: { _, _ in nil }, errorReporter: failures.add)

        bridge.track(
            name: "checkout_started", parameters: [:], isScreenView: false,
            needsTranslation: false, kotlinEvent: KotlinCheckoutStarted())

        #expect(failures.all.isEmpty)
    }

    @Test func aUserPropertyStaysAUserProperty() {
        bridge().set(name: "plan", value: .string("pro"), isUserProperty: true)
        bridge().set(name: "theme", value: .string("dark"), isUserProperty: false)

        #expect(analytics.properties[0] is any UserProperty)
        #expect(!(analytics.properties[1] is any UserProperty))
        analytics.assertPropertySet("plan", "pro")
    }

    @Test func theOtherCallsReachTheVendor() {
        let bridge = bridge()
        bridge.start()
        bridge.setEnabled(true)
        bridge.identify(userId: "user-42")
        bridge.flush()
        bridge.reset()

        #expect(analytics.records.count == 5)
        analytics.assertIdentified("user-42")
    }
}

/// Collects reported failures. Reports can come from any thread, hence the lock.
private final class Failures: @unchecked Sendable {
    private let lock = NSLock()
    private var failures: [AnalyticsFailure] = []

    var all: [AnalyticsFailure] {
        lock.lock()
        defer { lock.unlock() }
        return failures
    }

    func add(_ failure: AnalyticsFailure) {
        lock.lock()
        defer { lock.unlock() }
        failures.append(failure)
    }
}
