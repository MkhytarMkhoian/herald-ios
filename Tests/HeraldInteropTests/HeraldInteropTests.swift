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

    private func bridge() -> HeraldBridge {
        HeraldBridge(
            Herald(providers: [
                HeraldProvider(
                    name: "fake", events: analytics, properties: analytics, identity: analytics,
                    lifecycle: analytics, consent: analytics)
            ]))
    }

    @Test func anEventKeepsItsNameAndTypedParameters() {
        bridge().track(
            name: "checkout_started",
            parameters: [
                "plan": .string("pro"), "seats": .int(3), "price": .double(9.5),
                "trial": .bool(true),
            ],
            isScreenView: false, kotlinEvent: KotlinCheckoutStarted())

        analytics.assertTracked("checkout_started") { event in
            event.param("plan", "pro")
            event.param("seats", 3)
            event.param("price", 9.5)
            event.param("trial", true)
        }
    }

    @Test func aScreenViewBecomesAScreenViewEvent() {
        bridge().track(
            name: "home", parameters: [:], isScreenView: true, kotlinEvent: KotlinCheckoutStarted())

        #expect(analytics.events.first is any ScreenViewEvent)
    }

    @Test func theKotlinEventKeepsItsLabels() {
        bridge().track(
            name: "profile_opened", parameters: [:], isScreenView: false,
            kotlinEvent: KotlinProfileOpened())
        bridge().track(
            name: "checkout_started", parameters: [:], isScreenView: false,
            kotlinEvent: KotlinCheckoutStarted())

        #expect(analytics.events[0].kotlinEvent is PersonalDataLabel)
        #expect(!(analytics.events[1].kotlinEvent is PersonalDataLabel))
    }

    @Test func aScreenViewKeepsItsKotlinEventToo() {
        bridge().track(
            name: "profile", parameters: [:], isScreenView: true, kotlinEvent: KotlinProfileOpened()
        )

        #expect(analytics.events.first?.kotlinEvent is PersonalDataLabel)
    }

    @Test func anEventFromSwiftHasNoKotlinEvent() {
        struct SwiftEvent: Event {
            var name: String { "swift_event" }
        }

        #expect(SwiftEvent().kotlinEvent == nil)
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
