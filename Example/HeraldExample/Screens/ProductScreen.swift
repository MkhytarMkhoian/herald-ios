import HeraldCore
import HeraldSwiftUI
import SwiftUI

/// A product's cart. It tracks its own events and doesn't know which vendors get them.
@MainActor
final class ProductModel: ObservableObject {
    static let price = 4.99

    let productId: String
    @Published private(set) var inCart = 0
    private var purchases = 0
    private let analytics: any EventTrackerService
    private let properties: any PropertyTrackerService

    init(
        productId: String, analytics: any EventTrackerService,
        properties: any PropertyTrackerService
    ) {
        self.productId = productId
        self.analytics = analytics
        self.properties = properties
    }

    func addToCart() {
        inCart += 1
        analytics.track(AddedToCart(productId: productId, price: Self.price))
    }

    func buy() {
        let items = inCart
        inCart = 0
        purchases += 1
        properties.set(PurchaseCount(count: purchases))
        analytics.track(OrderPaid(items: items, total: Double(items) * Self.price))
    }
}

struct ProductScreen: View {
    static let offers = ["bundle", "gift_card", "student", "family"]

    @StateObject private var model: ProductModel

    init(
        productId: String, analytics: any EventTrackerService,
        properties: any PropertyTrackerService
    ) {
        _model = StateObject(
            wrappedValue: ProductModel(
                productId: productId, analytics: analytics, properties: properties))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(ProductModel.price, format: .currency(code: "USD"))
                    .font(.largeTitle)
                Button("Add to cart") { model.addToCart() }
                    .buttonStyle(.borderedProminent)
                Button("Buy \(model.inCart)") { model.buy() }
                    .buttonStyle(.bordered)
                    .disabled(model.inCart == 0)

                Text("Offers")
                    .font(.headline)
                    .padding(.top)
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(Self.offers, id: \.self) { offerId in
                            OfferCard(offerId: offerId)
                                // From HeraldSwiftUI: once each time it's been half on screen
                                // for a second.
                                .trackImpression(
                                    OfferShown(offerId: offerId), minVisibleDuration: 1)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(model.productId)
        .trackScreenView(ProductViewed(productId: model.productId))
    }
}

/// A small view with no model: it tracks its tap through the tracker in the environment.
struct OfferCard: View {
    let offerId: String
    @Environment(\.eventTracker) private var analytics

    var body: some View {
        Button {
            analytics.track(OfferTapped(offerId: offerId))
        } label: {
            Text(offerId)
                .frame(width: 160, height: 100)
                .background(.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
