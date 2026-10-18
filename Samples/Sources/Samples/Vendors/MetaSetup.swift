import FBSDKCoreKit
import Foundation
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

func gatedMetaProvider(featureFactories: [any MetaEventTrackerFactory]) -> HeraldProvider {
    let tracker = MetaAnalyticsTrackerService(
        eventTrackerFactory: CompositeMetaEventTrackerFactory(featureFactories))
    let service = MetaAnalyticsService()
    // --8<-- [start:gate]
    let gate = ConsentGate(events: tracker, consent: service)

    let provider = HeraldProvider(
        name: "meta",
        events: gate,  // dropped while consent is off
        identity: service,
        lifecycle: service,
        consent: gate  // keeps the answer, then turns Meta's own switch
    )
    // --8<-- [end:gate]
    return provider
}

// --8<-- [start:gate-class]
/// Meta's own switch doesn't stop the events your app logs, so this drops them while consent is
/// off. Herald's services must be safe to share between threads, so a lock guards the answer.
final class ConsentGate: EventTrackerService, ConsentService, @unchecked Sendable {
    private let events: any EventTrackerService
    private let consent: any ConsentService
    private let lock = NSLock()
    private var enabled = false

    init(events: any EventTrackerService, consent: any ConsentService) {
        self.events = events
        self.consent = consent
    }

    func track(_ event: any Event) {
        if lock.withLock({ enabled }) {
            events.track(event)
        }
    }

    func setEnabled(_ enabled: Bool) {
        lock.withLock { self.enabled = enabled }
        consent.setEnabled(enabled)
    }
}
// --8<-- [end:gate-class]

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
