import FirebaseAnalytics
import HeraldCore
import HeraldFirebase

// --8<-- [start:marker]
/// Money returned to a customer. Your app's idea, so your app's marker.
protocol RefundEvent: Event {
    var amount: Double { get }
    var currency: String { get }
    var transactionId: String { get }
}

struct TicketRefunded: RefundEvent {
    let amount: Double
    let currency: String
    let transactionId: String

    var name: String { "ticket_refunded" }
}
// --8<-- [end:marker]

// --8<-- [start:marker-tracker]
struct RefundFirebaseEventTracker: FirebaseEventTracker {
    let event: any RefundEvent

    func track() {
        var parameters = event.parameters.toFirebaseParameters()
        parameters["transaction_id"] = event.transactionId
        parameters["value"] = event.amount
        parameters["currency"] = event.currency
        Analytics.logEvent("refund", parameters: parameters)  // GA4's reserved refund
    }
}

struct RefundFirebaseEventTrackerFactory: FirebaseEventTrackerFactory {
    func create(_ event: any Event) -> Resolution<any FirebaseEventTracker> {
        if let refund = event as? any RefundEvent {
            return .claimed([RefundFirebaseEventTracker(event: refund)])
        }
        return .declined
    }
}
// --8<-- [end:marker-tracker]

// --8<-- [start:structured]
/// Names an event by where it happened, so two features can't pick the same name.
protocol StructuredEvent: Event {
    var screen: String { get }
    var component: String { get }
    var action: String { get }
}

extension StructuredEvent {
    var name: String {
        var parts: [String] = []
        for part in [screen, component, action] where !part.isEmpty {
            parts.append(part)
        }
        return parts.joined(separator: "_")
    }
}

struct CheckoutPayButtonTapped: StructuredEvent {
    var screen: String { "checkout" }
    var component: String { "pay_button" }
    var action: String { "tap" }
}
// --8<-- [end:structured]

// --8<-- [start:structured-tracker]
struct StructuredFirebaseEventTracker: FirebaseEventTracker {
    let event: any StructuredEvent

    func track() {
        var parameters = event.parameters.toFirebaseParameters()
        parameters["screen"] = event.screen  // your call: spread the structure across
        parameters["action"] = event.action  // parameters, or let the name carry it alone
        Analytics.logEvent(event.component, parameters: parameters)
    }
}
// --8<-- [end:structured-tracker]
