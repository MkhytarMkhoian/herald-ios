import HeraldCore
import HeraldFirebase

// --8<-- [start:feature]
// The checkout feature module exposes its factories, and knows nothing about the app's other
// vendors.
enum CheckoutFactories {
    static func firebase() -> [any FirebaseEventTrackerFactory] {
        [CheckoutFirebaseEventTrackerFactory()]
    }
}
// --8<-- [end:feature]

// --8<-- [start:root]
// The app builds the Firebase provider from whatever the features contribute.
func firebaseProvider(
    featureFactories: [any FirebaseEventTrackerFactory]  // from every feature, any order
) -> HeraldProvider {
    let tracker = FirebaseAnalyticsTrackerService(
        eventTrackerFactory: CompositeFirebaseEventTrackerFactory(
            featureFactories + [
                ScreenViewFirebaseEventTrackerFactory(),  // then placed by hand
                GenericFirebaseEventTrackerFactory(),
            ]),
        propertySetterFactory: GenericFirebasePropertySetterFactory()
    )
    let service = FirebaseAnalyticsService()
    return HeraldProvider(
        name: "firebase",
        events: tracker,
        properties: tracker,
        identity: service,
        lifecycle: service,
        consent: service
    )
}

func appFirebaseProvider() -> HeraldProvider {
    firebaseProvider(
        featureFactories: CheckoutFactories.firebase()
            // + ProfileAnalytics.firebase(), one line per feature
    )
}
// --8<-- [end:root]

// --8<-- [start:vendor-module]
// The Firebase module knows every feature's events, through their API modules, so it lists the
// factories itself.
func firebaseVendorProvider() -> HeraldProvider {
    let tracker = FirebaseAnalyticsTrackerService(
        eventTrackerFactory: CompositeFirebaseEventTrackerFactory([
            CheckoutFirebaseEventTrackerFactory(),  // one for each feature that needs one
            ScreenViewFirebaseEventTrackerFactory(),
            GenericFirebaseEventTrackerFactory(),
        ]),
        propertySetterFactory: GenericFirebasePropertySetterFactory()
    )
    let service = FirebaseAnalyticsService()
    return HeraldProvider(
        name: "firebase",
        events: tracker,
        properties: tracker,
        identity: service,
        lifecycle: service,
        consent: service
    )
}
// --8<-- [end:vendor-module]

// --8<-- [start:interface]
// The checkout API module: one method for each thing that can happen. No Herald, no vendors.
protocol CheckoutAnalytics {
    func checkoutStarted(plan: String, seats: Int)
    func paymentFailed(reason: String)
}
// --8<-- [end:interface]

// --8<-- [start:feature]
// The checkout feature calls the protocol, and knows nothing about analytics libraries.
final class PaymentViewModel {
    private let analytics: any CheckoutAnalytics

    init(analytics: any CheckoutAnalytics) {
        self.analytics = analytics
    }

    func onPaymentFailed(reason: String) {
        analytics.paymentFailed(reason: reason)
    }
}
// --8<-- [end:feature]

// --8<-- [start:implementation]
// The analytics module owns the events, and turns each call into one.
struct PaymentFailed: Event, Equatable {
    let reason: String

    var name: String { "payment_failed" }
    var parameters: [String: AnalyticsValue] { ["reason": .string(reason)] }
}

final class HeraldCheckoutAnalytics: CheckoutAnalytics {
    private let analytics: any EventTrackerService

    init(analytics: any EventTrackerService) {
        self.analytics = analytics
    }

    func checkoutStarted(plan: String, seats: Int) {
        analytics.track(CheckoutStarted(plan: plan, seats: seats))
    }

    func paymentFailed(reason: String) {
        analytics.track(PaymentFailed(reason: reason))
    }
}
// --8<-- [end:implementation]

// --8<-- [start:binding]
// The app hands each feature its protocol, backed by Herald.
func makePaymentViewModel(herald: Herald) -> PaymentViewModel {
    PaymentViewModel(analytics: HeraldCheckoutAnalytics(analytics: herald))
}
// --8<-- [end:binding]
