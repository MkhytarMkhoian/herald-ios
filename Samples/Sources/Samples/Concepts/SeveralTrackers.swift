import HeraldCore
import HeraldMixpanel
@preconcurrency import Mixpanel

// --8<-- [start:event]
struct OrderPaid: Event {
    let orderId: String
    let total: Double

    var name: String { "order_paid" }
    var parameters: [String: AnalyticsValue] {
        ["order_id": .string(orderId), "total": .double(total)]
    }
}
// --8<-- [end:event]

// --8<-- [start:tracker]
// Adds the amount to the buyer's profile, which Mixpanel's revenue reports read.
struct ChargeMixpanelEventTracker: MixpanelEventTracker {
    let event: OrderPaid
    let mixpanel: MixpanelInstance

    func track() {
        mixpanel.people.trackCharge(amount: event.total)
    }
}
// --8<-- [end:tracker]

// --8<-- [start:factory]
// Mixpanel isn't marked Sendable, so a factory that stores it needs `@preconcurrency import Mixpanel`.
struct CheckoutMixpanelEventTrackerFactory: MixpanelEventTrackerFactory {
    let mixpanel: MixpanelInstance

    func create(_ event: any Event) -> Resolution<any MixpanelEventTracker> {
        guard let order = event as? OrderPaid else {
            return .declined
        }
        return .claimed([
            // 1. the order_paid event, as usual; 2. a charge on the buyer's profile
            GenericMixpanelEventTracker(event: order, mixpanel: mixpanel),
            ChargeMixpanelEventTracker(event: order, mixpanel: mixpanel),
        ])
    }
}
// --8<-- [end:factory]
