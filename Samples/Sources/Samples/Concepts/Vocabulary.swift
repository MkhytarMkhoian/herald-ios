import HeraldCore

// --8<-- [start:no-parameters]
struct SignInTapped: Event {
    var name: String { "sign_in_tapped" }
}
// --8<-- [end:no-parameters]

// --8<-- [start:parameters]
struct PlanSelected: Event, Equatable {
    let plan: String
    let seats: Int
    let price: Double
    let trial: Bool

    var name: String { "plan_selected" }
    var parameters: [String: AnalyticsValue] {
        [
            "plan": .string(plan),
            "seats": .int(seats),
            "price": .double(price),
            "trial": .bool(trial),
        ]
    }
}
// --8<-- [end:parameters]

// --8<-- [start:screen-view]
struct ProductScreenViewed: ScreenViewEvent {
    let productId: String

    var name: String { "product" }  // the screen's name in GA4, Mixpanel and Amplitude
    var parameters: [String: AnalyticsValue] { ["product_id": .string(productId)] }
}
// --8<-- [end:screen-view]

// --8<-- [start:properties]
// Describes the session: a super property in Mixpanel, sent with every later event.
struct AppTheme: Property {
    let dark: Bool

    var name: String { "app_theme" }
    var value: AnalyticsValue { .string(dark ? "dark" : "light") }
}

// Describes the person: Mixpanel's people profile, Amplitude's user properties.
struct PurchaseCount: UserProperty {
    let count: Int

    var name: String { "total_purchases" }
    var value: AnalyticsValue { .int(count) }
}
// --8<-- [end:properties]
