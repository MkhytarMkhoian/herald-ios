import FirebaseCore
import HeraldCore
import HeraldLog
import UIKit

// --8<-- [start:event]
struct CheckoutStarted: Event, Equatable {
    let plan: String
    let seats: Int

    var name: String { "checkout_started" }
    var parameters: [String: AnalyticsValue] { ["plan": .string(plan), "seats": .int(seats)] }
}
// --8<-- [end:event]

func makeHerald() -> Herald {
    // --8<-- [start:herald]
    // Where the log lines go: print fits as-is.
    let logger: AnalyticsLogger = { message in print(message) }

    // Handles events and user properties, using Herald's ready-made factories.
    let logTracker = LogAnalyticsTrackerService(
        eventTrackerFactory: CompositeLogEventTrackerFactory([
            ScreenViewLogEventTrackerFactory(logger: logger),  // screen views
            GenericLogEventTrackerFactory(logger: logger),  // every other event
        ]),
        propertySetterFactory: GenericLogPropertySetterFactory(logger: logger)
    )
    // Handles the rest: start-up, sign-in and sign-out, consent.
    let logService = LogAnalyticsService(logger: logger)

    let herald = Herald(providers: [
        HeraldProvider(
            name: "log",
            events: logTracker,
            properties: logTracker,
            identity: logService,
            lifecycle: logService,
            consent: logService
        )
    ])
    // --8<-- [end:herald]
    return herald
}

func quickStartWithFirebase() -> Herald {
    let logger: AnalyticsLogger = { message in print(message) }
    let logTracker = LogAnalyticsTrackerService(
        eventTrackerFactory: GenericLogEventTrackerFactory(logger: logger),
        propertySetterFactory: GenericLogPropertySetterFactory(logger: logger)
    )
    let logService = LogAnalyticsService(logger: logger)
    // --8<-- [start:add-firebase]
    let herald = Herald(providers: [
        HeraldProvider(
            name: "log",
            events: logTracker,
            properties: logTracker,
            identity: logService,
            lifecycle: logService,
            consent: logService
        ),
        firebaseProvider(),  // the new line
    ])
    // --8<-- [end:add-firebase]
    return herald
}

// --8<-- [start:track]
final class CheckoutViewModel {
    private let analytics: any EventTrackerService

    init(analytics: any EventTrackerService) {
        self.analytics = analytics
    }

    func onCheckout(plan: String, seats: Int) {
        analytics.track(CheckoutStarted(plan: plan, seats: seats))
    }
}
// --8<-- [end:track]

// --8<-- [start:app]
final class AppDelegate: NSObject, UIApplicationDelegate {
    let herald = makeHerald()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()  // vendors set themselves up first, as their guides say
        herald.start()
        return true
    }
}
// --8<-- [end:app]
