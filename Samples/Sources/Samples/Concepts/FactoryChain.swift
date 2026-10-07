import FirebaseAnalytics
import HeraldAdjust
import HeraldCore
import HeraldFirebase

struct PayTapped: Event {
    let plan: String

    var name: String { "pay_tapped" }
    var parameters: [String: AnalyticsValue] { ["plan": .string(plan)] }
}

struct CardNumberSeen: Event {
    let last4: String

    var name: String { "card_number_seen" }
}

struct CheckoutCompleted: Event {
    let value: Double
    let currency: String

    var name: String { "checkout_completed" }
    var parameters: [String: AnalyticsValue] {
        ["value": .double(value), "currency": .string(currency)]
    }
}

// --8<-- [start:tracker]
struct PurchaseFirebaseEventTracker: FirebaseEventTracker {
    let event: CheckoutCompleted

    func track() {
        // GA4's recommended purchase event, with the typed parameters.
        Analytics.logEvent("purchase", parameters: event.parameters.toFirebaseParameters())
    }
}
// --8<-- [end:tracker]

// --8<-- [start:factory]
struct CheckoutFirebaseEventTrackerFactory: FirebaseEventTrackerFactory {
    func create(_ event: any Event) -> Resolution<any FirebaseEventTracker> {
        if let checkout = event as? CheckoutCompleted {
            return .claimed([PurchaseFirebaseEventTracker(event: checkout)])
        }
        if event is PayTapped {
            return .claimed([GenericFirebaseEventTracker(event: event)])  // Herald's own
        }
        if event is CardNumberSeen {
            return .dropped  // mine, and it goes nowhere
        }
        return .declined  // not mine: ask the next factory
    }
}
// --8<-- [end:factory]

func chains() -> [any FirebaseEventTrackerFactory] {
    // --8<-- [start:chain]
    let chain = CompositeFirebaseEventTrackerFactory([
        CheckoutFirebaseEventTrackerFactory(),  // feature factories first
        ScreenViewFirebaseEventTrackerFactory(),  // then Herald's screen views
        GenericFirebaseEventTrackerFactory(),  // then everything else
    ])
    // --8<-- [end:chain]

    // --8<-- [start:strict]
    let strict = CompositeFirebaseEventTrackerFactory([
        CheckoutFirebaseEventTrackerFactory(),
        ScreenViewFirebaseEventTrackerFactory(),
        RequireMappedFirebaseEventTrackerFactory(),  // an unclaimed event is reported
    ])
    // --8<-- [end:strict]
    return [chain, strict]
}

func defaultRules(
    firebaseFactories: [any FirebaseEventTrackerFactory],
    adjustFactories: [any AdjustEventTrackerFactory]
) -> [any Sendable] {
    // --8<-- [start:default]
    // Firebase: events without a factory of their own are still sent, under their own name.
    let firebase = CompositeFirebaseEventTrackerFactory(
        firebaseFactories + [GenericFirebaseEventTrackerFactory()])

    // Adjust: nothing at the end, so only events a factory handled are sent.
    let adjust = CompositeAdjustEventTrackerFactory(adjustFactories)
    // --8<-- [end:default]
    return [firebase, adjust]
}
