import HeraldTesting
import Testing

@testable import HeraldExample

@MainActor
@Suite struct ProductModelTests {
    @Test func buyingReportsThePurchaseCountThenTheOrderWithItsTotal() {
        let analytics = FakeAnalyticsProvider()
        let model = ProductModel(productId: "day_pass", analytics: analytics, properties: analytics)

        model.addToCart()
        model.addToCart()
        model.buy()

        analytics.assertTrackedTimes("added_to_cart", 2)
        analytics.assertTracked("order_paid") { event in
            event.param("items", 2)
            event.param("total", 9.98)
        }
        analytics.assertNothingElseTracked()
        analytics.assertPropertySet("total_purchases", 1)
    }
}
