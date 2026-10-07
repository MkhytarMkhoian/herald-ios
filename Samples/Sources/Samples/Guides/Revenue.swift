@preconcurrency import AmplitudeSwift
import AppsFlyerLib
import HeraldAdjust
import HeraldAmplitude
import HeraldAppsFlyer
import HeraldCore

// --8<-- [start:purchase]
struct SubscriptionPurchased: Event {
    let plan: String
    let price: Double
    let currency: String
    let orderId: String

    // Firebase and Mixpanel log it as it is: GA4's recommended purchase, with typed parameters.
    var name: String { "purchase" }
    var parameters: [String: AnalyticsValue] {
        ["value": .double(price), "currency": .string(currency), "plan": .string(plan)]
    }
}
// --8<-- [end:purchase]

// --8<-- [start:mappings]
extension SubscriptionPurchased {
    // Adjust: the tokened event, plus revenue, counted once per transaction.
    func toAdjustRevenueEvent() -> AdjustRevenueEvent {
        AdjustRevenueEvent(
            name: name, revenue: price, currency: currency, deduplicationId: orderId,
            parameters: parameters)
    }

    // AppsFlyer: af_purchase, with the amount under af_revenue.
    func toAppsFlyerPurchaseEvent() -> AppsFlyerPurchaseEvent {
        AppsFlyerPurchaseEvent(
            name: name, revenue: price, currency: currency, contentId: plan, orderId: orderId,
            parameters: parameters)
    }

    // Amplitude: the revenue API, deduplicated by the insert id.
    func toAmplitudeRevenueEvent() -> AmplitudeRevenueEvent {
        AmplitudeRevenueEvent(
            name: name, price: price, productId: plan, currency: currency, insertId: orderId,
            parameters: parameters)
    }
}
// --8<-- [end:mappings]

// --8<-- [start:factories]
struct BillingAdjustEventTrackerFactory: AdjustEventTrackerFactory {
    func create(_ event: any Event) -> Resolution<any AdjustEventTracker> {
        guard let purchase = event as? SubscriptionPurchased else {
            return .declined
        }
        return .claimed([
            RevenueAdjustEventTracker(event: purchase.toAdjustRevenueEvent(), eventToken: "abc123")
        ])
    }
}

struct BillingAppsFlyerEventTrackerFactory: AppsFlyerEventTrackerFactory {
    func create(_ event: any Event) -> Resolution<any AppsFlyerEventTracker> {
        guard let purchase = event as? SubscriptionPurchased else {
            return .declined
        }
        return .claimed([PurchaseAppsFlyerEventTracker(event: purchase.toAppsFlyerPurchaseEvent())])
    }
}

// Amplitude isn't marked Sendable, so a factory that stores it needs
// `@preconcurrency import AmplitudeSwift`.
struct BillingAmplitudeEventTrackerFactory: AmplitudeEventTrackerFactory {
    let amplitude: Amplitude

    func create(_ event: any Event) -> Resolution<any AmplitudeEventTracker> {
        guard let purchase = event as? SubscriptionPurchased else {
            return .declined
        }
        return .claimed([
            RevenueAmplitudeEventTracker(
                event: purchase.toAmplitudeRevenueEvent(), amplitude: amplitude)
        ])
    }
}
// --8<-- [end:factories]

// --8<-- [start:ad-impression]
struct AdImpression: Event {
    let revenue: Double
    let network: String

    var name: String { "ad_impression" }
    var parameters: [String: AnalyticsValue] { ["network": .string(network)] }

    func toAdjustAdRevenueEvent() -> AdjustAdRevenueEvent {
        AdjustAdRevenueEvent(
            name: name, source: "applovin_max_sdk", revenue: revenue, currency: "USD",
            adRevenueNetwork: network, parameters: parameters)
    }

    func toAppsFlyerAdRevenueEvent() -> AppsFlyerAdRevenueEvent {
        AppsFlyerAdRevenueEvent(
            name: name, monetizationNetwork: network, mediationNetwork: .applovinMax,
            revenue: revenue, currency: "USD", parameters: parameters)
    }
}

struct AdsAdjustEventTrackerFactory: AdjustEventTrackerFactory {
    func create(_ event: any Event) -> Resolution<any AdjustEventTracker> {
        guard let impression = event as? AdImpression else {
            return .declined
        }
        return .claimed([AdRevenueAdjustEventTracker(event: impression.toAdjustAdRevenueEvent())])
    }
}

struct AdsAppsFlyerEventTrackerFactory: AppsFlyerEventTrackerFactory {
    func create(_ event: any Event) -> Resolution<any AppsFlyerEventTracker> {
        guard let impression = event as? AdImpression else {
            return .declined
        }
        return .claimed([
            AdRevenueAppsFlyerEventTracker(event: impression.toAppsFlyerAdRevenueEvent())
        ])
    }
}
// --8<-- [end:ad-impression]
