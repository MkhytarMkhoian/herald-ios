import HeraldAppsFlyer
import HeraldCore

// --8<-- [start:event]
// The event: what happened, in your app's words. It knows nothing about AppsFlyer.
struct TicketPurchased: Event {
    let fare: String
    let price: Double
    let currency: String

    var name: String { "ticket_purchased" }
    var parameters: [String: AnalyticsValue] { ["fare": .string(fare)] }
}
// --8<-- [end:event]

// --8<-- [start:mapping]
// The mapping: the only code that knows how AppsFlyer wants a purchase.
extension TicketPurchased {
    func toAppsFlyerPurchaseEvent() -> AppsFlyerPurchaseEvent {
        AppsFlyerPurchaseEvent(
            name: name,
            revenue: price,  // sent as af_revenue
            currency: currency,
            contentId: fare,
            parameters: parameters
        )
    }
}

// The factory: sends the purchase to AppsFlyer, using the mapping above.
struct TicketsAppsFlyerEventTrackerFactory: AppsFlyerEventTrackerFactory {
    func create(_ event: any Event) -> Resolution<any AppsFlyerEventTracker> {
        if let ticket = event as? TicketPurchased {
            return .claimed([
                PurchaseAppsFlyerEventTracker(event: ticket.toAppsFlyerPurchaseEvent())
            ])
        }
        return .declined  // not mine
    }
}
// --8<-- [end:mapping]
