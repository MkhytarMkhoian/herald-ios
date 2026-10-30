import Testing

@testable import Samples

// --8<-- [start:fake]
// The feature's test fakes its own protocol: no Herald, no vendors.
final class FakeCheckoutAnalytics: CheckoutAnalytics {
    var checkouts: [(plan: String, seats: Int)] = []
    var failedPayments: [String] = []

    func checkoutStarted(plan: String, seats: Int) {
        checkouts.append((plan, seats))
    }

    func paymentFailed(reason: String) {
        failedPayments.append(reason)
    }
}

@Test func aFailedPaymentReportsItsReason() {
    let analytics = FakeCheckoutAnalytics()

    PaymentViewModel(analytics: analytics).onPaymentFailed(reason: "card_declined")

    #expect(analytics.failedPayments == ["card_declined"])
    #expect(analytics.checkouts.isEmpty)
}
// --8<-- [end:fake]
