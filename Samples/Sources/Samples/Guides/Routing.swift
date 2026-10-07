import HeraldAdjust
import HeraldCore
import HeraldFirebase

func routing(featureFirebaseFactories: [any FirebaseEventTrackerFactory]) -> [any Sendable] {
    // --8<-- [start:two-kinds]
    // Firebase gets everything: events no factory took are sent under their own name.
    let firebaseEvents = CompositeFirebaseEventTrackerFactory(
        featureFirebaseFactories + [
            ScreenViewFirebaseEventTrackerFactory(),
            GenericFirebaseEventTrackerFactory(),  // everything else
        ])

    // Adjust gets only events with a dashboard token.
    let adjustEvents = CompositeAdjustEventTrackerFactory([
        TokenAdjustEventTrackerFactory(tokens: ["checkout_completed": "abc123"])
    ])  // nothing at the end: other events aren't sent
    // --8<-- [end:two-kinds]
    return [firebaseEvents, adjustEvents]
}

// --8<-- [start:drop-property]
struct AppAdjustPropertySetterFactory: AdjustPropertySetterFactory {
    func create(_ property: any Property) -> Resolution<any AdjustPropertySetter> {
        if property is AppTheme {
            return .dropped  // a UI preference, not an attribution signal
        }
        return .declined
    }
}
// --8<-- [end:drop-property]
