import HeraldCore
import HeraldTesting
import Testing

// --8<-- [start:app]
private struct CheckoutStarted: Event {
    let plan: String
    let seats: Int

    var name: String { "checkout_started" }
    var parameters: [String: AnalyticsValue] { ["plan": .string(plan), "seats": .int(seats)] }
}

private struct OrderPaid: Event {
    let total: Double

    var name: String { "order_paid" }
    var parameters: [String: AnalyticsValue] { ["total": .double(total)] }
}

private struct PurchaseCount: UserProperty {
    let count: Int

    var name: String { "total_purchases" }
    var value: AnalyticsValue { .int(count) }
}

private final class CheckoutViewModel {
    private let events: any EventTrackerService
    private let properties: any PropertyTrackerService

    init(events: any EventTrackerService, properties: any PropertyTrackerService) {
        self.events = events
        self.properties = properties
    }

    func start(plan: String, seats: Int) {
        events.track(CheckoutStarted(plan: plan, seats: seats))
    }

    func pay(total: Double, purchases: Int) {
        properties.set(PurchaseCount(count: purchases))
        events.track(OrderPaid(total: total))
    }
}

private final class SessionViewModel {
    private let identity: any IdentifiableUserService

    init(identity: any IdentifiableUserService) {
        self.identity = identity
    }

    func signIn(userId: String) {
        identity.identify(Identity(userId: userId))
    }

    func signOut() {
        identity.reset()
    }
}
// --8<-- [end:app]

@Suite struct Showcase {
    let analytics = FakeAnalyticsProvider()

    @Test func throughARealHerald() {
        // --8<-- [start:through-herald]
        let analytics = FakeAnalyticsProvider()
        let herald = Herald(providers: [
            HeraldProvider(name: "test", events: analytics, properties: analytics)
        ])

        CheckoutViewModel(events: herald, properties: herald).start(plan: "pro", seats: 3)

        analytics.assertTracked("checkout_started")
        // --8<-- [end:through-herald]
    }

    @Test func parametersComparedByType() {
        CheckoutViewModel(events: analytics, properties: analytics).start(plan: "pro", seats: 3)

        // --8<-- [start:parameters]
        analytics.assertTracked("checkout_started") { event in
            event.param("plan", "pro")
            event.param("seats", 3)  // the number 3: the text "3" would fail
        }
        // --8<-- [end:parameters]
    }

    @Test func countingAbsenceAndNothingElse() {
        let checkout = CheckoutViewModel(events: analytics, properties: analytics)
        checkout.start(plan: "pro", seats: 3)
        checkout.start(plan: "pro", seats: 3)

        // --8<-- [start:counting]
        analytics.assertTrackedTimes("checkout_started", 2)  // repeats are expected
        analytics.assertNotTracked("order_paid")
        analytics.assertNothingElseTracked()  // every tracked event was checked above
        // --8<-- [end:counting]
    }

    @Test func propertiesTheLastValueCounts() {
        // --8<-- [start:properties]
        let checkout = CheckoutViewModel(events: analytics, properties: analytics)
        checkout.pay(total: 9.99, purchases: 1)
        checkout.pay(total: 4.99, purchases: 2)

        analytics.assertPropertySet("total_purchases", 2)  // 1 was overwritten by 2
        // --8<-- [end:properties]
    }

    @Test func orderAcrossDifferentCalls() {
        // --8<-- [start:order]
        CheckoutViewModel(events: analytics, properties: analytics).pay(total: 9.99, purchases: 1)

        #expect(
            analytics.records == [
                .propertySet(PurchaseCount(count: 1)), .tracked(OrderPaid(total: 9.99)),
            ])
        // --8<-- [end:order]
    }

    @Test func signInAndSignOut() {
        // --8<-- [start:identity]
        let session = SessionViewModel(identity: analytics)
        session.signIn(userId: "user-42")
        session.signOut()

        analytics.assertIdentified("user-42")  // passes even after the later reset
        #expect(analytics.records == [.identified(Identity(userId: "user-42")), .reset])
        // --8<-- [end:identity]
    }

    @Test func yourOwnChecks() throws {
        CheckoutViewModel(events: analytics, properties: analytics).pay(total: 9.99, purchases: 1)

        // --8<-- [start:custom-checks]
        analytics.assertTracked("order_paid") { event in
            let order = event.event as? OrderPaid
            #expect(abs((order?.total ?? 0) - 9.99) < 0.001)
        }
        #expect(analytics.events.count == 1)
        #expect(analytics.properties.first?.value == .int(1))
        // --8<-- [end:custom-checks]
    }

    @Test func startingOverMidTest() {
        // --8<-- [start:clear]
        let checkout = CheckoutViewModel(events: analytics, properties: analytics)
        checkout.start(plan: "pro", seats: 3)
        analytics.clear()  // forget what came before

        checkout.pay(total: 9.99, purchases: 1)

        analytics.assertTracked("order_paid")
        analytics.assertNothingElseTracked()
        // --8<-- [end:clear]
    }
}
