import HeraldCore

/// The wrapper most apps already have, called from everywhere.
final class LegacyAnalytics: Sendable {
    func logEvent(name: String, params: [String: String]) {}
}

// --8<-- [start:bridge]
// Step 1: Herald forwards to the old wrapper, so migrated and unmigrated code report the same.
struct LegacyEventTracker: EventTrackerService {
    let legacy: LegacyAnalytics

    func track(_ event: any Event) {
        var params: [String: String] = [:]
        for (key, value) in event.parameters {
            params[key] = value.asString
        }
        legacy.logEvent(name: event.name, params: params)
    }
}

func migratingHerald(legacy: LegacyAnalytics) -> Herald {
    Herald(providers: [HeraldProvider(name: "legacy", events: LegacyEventTracker(legacy: legacy))])
}
// --8<-- [end:bridge]
