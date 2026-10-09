import HeraldCore
import HeraldTesting
import Testing

@testable import HeraldInterop

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
            markers: [])

        analytics.assertTracked("checkout_started") { event in
            event.param("plan", "pro")
            event.param("seats", 3)
            event.param("price", 9.5)
            event.param("trial", true)
        }
    }

    @Test func theScreenViewMarkerMakesAScreenViewEvent() {
        bridge().track(name: "home", parameters: [:], markers: ["screen_view"])

        #expect(analytics.events.first is any ScreenViewEvent)
    }

    @Test func otherMarkersStayOnTheEvent() {
        bridge().track(name: "profile_opened", parameters: [:], markers: ["personal_data"])

        let event = analytics.events.first as? BridgedEvent
        #expect(event?.markers == ["personal_data"])
        #expect(!(analytics.events.first is any ScreenViewEvent))
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

        #expect(
            analytics.records.map { record in "\(record)" }.count == 5)
        analytics.assertIdentified("user-42")
    }
}
