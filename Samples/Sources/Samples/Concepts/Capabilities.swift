import HeraldCore

// --8<-- [start:consumers]
final class PaywallViewModel {
    private let analytics: any EventTrackerService

    init(analytics: any EventTrackerService) {
        self.analytics = analytics
    }

    func onPlanSelected(plan: String, seats: Int) {
        analytics.track(PlanSelected(plan: plan, seats: seats, price: 9.99, trial: false))
    }
}

final class PrivacySettingsViewModel {
    private let consent: any ConsentService

    init(consent: any ConsentService) {
        self.consent = consent
    }

    func onAnalyticsToggled(allowed: Bool) {
        consent.setEnabled(allowed)
    }
}
// --8<-- [end:consumers]

// --8<-- [start:fake]
/// A fake is a small class, because the protocol has one method. A test calls it from one thread,
/// so it skips the locking a shared tracker would need: hence `@unchecked Sendable`.
final class RecordingEventTracker: EventTrackerService, @unchecked Sendable {
    var tracked: [any Event] = []

    func track(_ event: any Event) {
        tracked.append(event)
    }
}
// --8<-- [end:fake]

func paywallWithFake() -> PaywallViewModel {
    PaywallViewModel(analytics: RecordingEventTracker())
}
