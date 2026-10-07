import HeraldCore
import HeraldSwiftUI
import SwiftUI
import UIKit

struct SettingsScreenViewed: ScreenViewEvent {
    var name: String { "settings" }
}

struct CheckoutLeft: Event {
    let itemsInCart: Int

    var name: String { "checkout_left" }
    var parameters: [String: AnalyticsValue] { ["items_in_cart": .int(itemsInCart)] }
}

struct PromoBannerTapped: Event {
    let promoId: String

    var name: String { "promo_banner_tapped" }
    var parameters: [String: AnalyticsValue] { ["promo_id": .string(promoId)] }
}

// Equatable, so an equal event keeps the count when the view is redrawn.
struct OfferShown: Event, Equatable {
    let offerId: String

    var name: String { "offer_shown" }
    var parameters: [String: AnalyticsValue] { ["offer_id": .string(offerId)] }
}

// --8<-- [start:plain]
// Plain Herald, no extra module: the view model tracks its screen view, once each time it's made.
@MainActor
final class SettingsViewModel: ObservableObject {
    init(analytics: any EventTrackerService) {
        analytics.track(SettingsScreenViewed())
    }
}
// --8<-- [end:plain]

// --8<-- [start:setup]
struct ShopApp: App {
    let herald = makeHerald()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ProductScreen(productId: "day_pass")
            }
            .eventTracker(herald)  // or your DI's EventTrackerService
        }
    }
}
// --8<-- [end:setup]

// --8<-- [start:screen-view]
struct ProductScreen: View {
    let productId: String

    var body: some View {
        Text(productId)
            .navigationTitle(productId)
            .trackScreenView(ProductScreenViewed(productId: productId))
    }
}
// --8<-- [end:screen-view]

struct CheckoutScreen: View {
    let itemsInCart: Int

    var body: some View {
        // --8<-- [start:on-screen]
        Text("Checkout")
            // pushed over, closed, or the app went to the background
            .track(CheckoutLeft(itemsInCart: itemsInCart), on: .hidden)
        // --8<-- [end:on-screen]
    }
}

// --8<-- [start:tap]
struct PromoBanner: View {
    let promoId: String
    @Environment(\.eventTracker) private var analytics

    var body: some View {
        Button("See the offer") {
            analytics.track(PromoBannerTapped(promoId: promoId))
        }
    }
}
// --8<-- [end:tap]

struct OfferList: View {
    let offerIds: [String]

    var body: some View {
        // --8<-- [start:impression]
        List(offerIds, id: \.self) { offerId in
            Text(offerId)
                .trackImpression(
                    OfferShown(offerId: offerId),
                    threshold: 0.5,  // half of it on screen
                    minVisibleDuration: 1  // for a second, not a fast scroll
                )
        }
        // --8<-- [end:impression]
    }
}

// --8<-- [start:uikit]
// UIKit needs no extra module: viewDidAppear runs each time the screen becomes visible.
final class ProductViewController: UIViewController {
    private let analytics: any EventTrackerService
    private let productId: String

    init(analytics: any EventTrackerService, productId: String) {
        self.analytics = analytics
        self.productId = productId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        analytics.track(ProductScreenViewed(productId: productId))
    }
}
// --8<-- [end:uikit]

// --8<-- [start:preview]
#Preview {
    ProductScreen(productId: "day_pass")  // the helpers track nothing in previews
}
// --8<-- [end:preview]
