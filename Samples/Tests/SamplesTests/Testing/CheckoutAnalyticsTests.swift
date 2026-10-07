import HeraldCore
import HeraldFirebase
import HeraldTesting
import Testing

@testable import Samples

// --8<-- [start:fake-provider]
@Test func checkoutReportsThePlanAndSeatsOnce() {
    let analytics = FakeAnalyticsProvider()
    let herald = Herald(providers: [
        HeraldProvider(name: "test", events: analytics, properties: analytics)
    ])

    CheckoutViewModel(analytics: herald).onCheckout(plan: "pro", seats: 3)

    analytics.assertTracked("checkout_started") { event in
        event.param("plan", "pro")
        event.param("seats", 3)  // an Int: the text "3" would fail here
    }
    analytics.assertNothingElseTracked()
}
// --8<-- [end:fake-provider]

// --8<-- [start:order]
@Test func thePurchaseCountIsSetBeforeThePurchaseEventThatShouldCarryIt() {
    let analytics = FakeAnalyticsProvider()
    let properties: any PropertyTrackerService = analytics
    let events: any EventTrackerService = analytics

    properties.set(PurchaseCount(count: 1))
    events.track(PlanSelected(plan: "pro", seats: 1, price: 9.99, trial: false))

    #expect(
        analytics.records == [
            .propertySet(PurchaseCount(count: 1)),
            .tracked(PlanSelected(plan: "pro", seats: 1, price: 9.99, trial: false)),
        ])
}
// --8<-- [end:order]

// --8<-- [start:single-capability]
@Test func aClassThatTakesOneCapabilityCanBeGivenTheFakeDirectly() {
    let analytics = FakeAnalyticsProvider()

    CheckoutViewModel(analytics: analytics).onCheckout(plan: "pro", seats: 3)

    #expect(analytics.records == [.tracked(CheckoutStarted(plan: "pro", seats: 3))])
}
// --8<-- [end:single-capability]

// --8<-- [start:factory]
@Test func theCheckoutFactoryClaimsItsEventsDropsTheCardNumberAndDeclinesTheRest() throws {
    let factory = CheckoutFirebaseEventTrackerFactory()

    let checkout = factory.create(CheckoutCompleted(value: 9.99, currency: "EUR"))
    #expect(try checkout.handlers().first is PurchaseFirebaseEventTracker)

    switch factory.create(CardNumberSeen(last4: "4242")) {
    case .dropped:
        break
    default:
        Issue.record("Expected the card number to be dropped")
    }

    switch factory.create(CheckoutStarted(plan: "pro", seats: 3)) {
    case .declined:
        break
    default:
        Issue.record("Expected another feature's event to be declined")
    }
}
// --8<-- [end:factory]
