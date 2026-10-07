import HeraldCore
import HeraldFirebase

// --8<-- [start:feature]
// The checkout feature module exposes its factories, and knows nothing about the app's other
// vendors.
enum CheckoutAnalytics {
    static func firebase() -> [any FirebaseEventTrackerFactory] {
        [CheckoutFirebaseEventTrackerFactory()]
    }
}
// --8<-- [end:feature]

// --8<-- [start:root]
// The app builds the Firebase provider from whatever the features contribute.
func firebaseProvider(
    featureFactories: [any FirebaseEventTrackerFactory]  // from every feature, any order
) -> HeraldProvider {
    let tracker = FirebaseAnalyticsTrackerService(
        eventTrackerFactory: CompositeFirebaseEventTrackerFactory(
            featureFactories + [
                ScreenViewFirebaseEventTrackerFactory(),  // then placed by hand
                GenericFirebaseEventTrackerFactory(),
            ]),
        propertySetterFactory: GenericFirebasePropertySetterFactory()
    )
    let service = FirebaseAnalyticsService()
    return HeraldProvider(
        name: "firebase",
        events: tracker,
        properties: tracker,
        identity: service,
        lifecycle: service,
        consent: service
    )
}

func appFirebaseProvider() -> HeraldProvider {
    firebaseProvider(
        featureFactories: CheckoutAnalytics.firebase()
            // + ProfileAnalytics.firebase(), one line per feature
    )
}
// --8<-- [end:root]
