import FBSDKCoreKit
import HeraldCore
import HeraldMeta

func metaProvider(featureFactories: [any MetaEventTrackerFactory]) -> HeraldProvider {
    // --8<-- [start:provider]
    let service = MetaAnalyticsService()  // uses Meta's shared AppEvents, set up at start-up

    let tracker = MetaAnalyticsTrackerService(
        // Your conversions. Nothing at the end, so other events aren't sent.
        eventTrackerFactory: CompositeMetaEventTrackerFactory(featureFactories)
    )

    let provider = HeraldProvider(
        name: "meta",
        events: tracker,  // no properties: Meta keeps no user attributes
        identity: service,
        lifecycle: service,
        consent: service
    )
    // --8<-- [end:provider]
    return provider
}

// --8<-- [start:conversions]
struct CheckoutMetaEventTrackerFactory: MetaEventTrackerFactory {
    func create(_ event: any Event) -> Resolution<any MetaEventTracker> {
        switch event {
        // A purchase: Meta's fb_mobile_purchase, which it counts as revenue.
        case let checkout as CheckoutCompleted:
            let purchase = MetaPurchaseEvent(
                name: checkout.name, amount: checkout.value, currency: checkout.currency,
                parameters: checkout.parameters)
            return .claimed([PurchaseMetaEventTracker(event: purchase)])
        // Any other conversion, under one of Meta's standard names.
        case let plan as PlanSelected:
            return .claimed([InitiatedCheckoutTracker(event: plan)])
        default:
            return .declined
        }
    }
}

struct InitiatedCheckoutTracker: MetaEventTracker {
    let event: any Event

    func track() {
        AppEvents.shared.logEvent(
            .initiatedCheckout, parameters: event.parameters.toMetaParameters())
    }
}
// --8<-- [end:conversions]
