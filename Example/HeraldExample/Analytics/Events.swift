import HeraldCore

// The app's events. Screens track these and never name a vendor.

struct HomeViewed: ScreenViewEvent {
    var name: String { "home" }
}

struct ProductViewed: ScreenViewEvent {
    let productId: String

    var name: String { "product" }
    var parameters: [String: AnalyticsValue] { ["product_id": .string(productId)] }
}

struct SettingsViewed: ScreenViewEvent {
    var name: String { "settings" }
}

struct AddedToCart: Event {
    let productId: String
    let price: Double

    var name: String { "added_to_cart" }
    var parameters: [String: AnalyticsValue] {
        ["product_id": .string(productId), "price": .double(price)]  // stays a number
    }
}

struct OrderPaid: Event {
    let items: Int
    let total: Double

    var name: String { "order_paid" }
    var parameters: [String: AnalyticsValue] { ["items": .int(items), "total": .double(total)] }
}

// Equatable, so an equal event keeps its impression count when the view is redrawn.
struct OfferShown: Event, Equatable {
    let offerId: String

    var name: String { "offer_shown" }
    var parameters: [String: AnalyticsValue] { ["offer_id": .string(offerId)] }
}

struct OfferTapped: Event {
    let offerId: String

    var name: String { "offer_tapped" }
    var parameters: [String: AnalyticsValue] { ["offer_id": .string(offerId)] }
}

/// About the session.
struct AppTheme: Property {
    let dark: Bool

    var name: String { "app_theme" }
    var value: AnalyticsValue { .string(dark ? "dark" : "light") }
}

/// About the person.
struct PurchaseCount: UserProperty {
    let count: Int

    var name: String { "total_purchases" }
    var value: AnalyticsValue { .int(count) }
}
