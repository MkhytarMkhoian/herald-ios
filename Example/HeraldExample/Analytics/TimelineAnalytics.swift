import Foundation
import HeraldCore

/// A provider of your own: it keeps every call as a line, for the timeline on the home screen.
///
/// Implementing Herald's protocols is all a provider takes. This one implements all five, so it
/// sees the whole story (consent, sign-in, events and properties) in the order Herald sent it.
///
/// It belongs to the main thread, like the screen that shows it, so the compiler knows it's safe
/// to share. Herald may call it from any thread, so each call hops to the main thread first.
@MainActor
final class TimelineAnalytics: ObservableObject, EventTrackerService, PropertyTrackerService,
    IdentifiableUserService, AnalyticsLifecycleService, ConsentService
{
    /// Newest first.
    @Published private(set) var lines: [String] = []

    nonisolated func track(_ event: any Event) {
        var parameters: [String] = []
        for key in event.parameters.keys.sorted() {
            parameters.append("\(key)=\(event.parameters[key]!.asString)")
        }
        var line = event is any ScreenViewEvent ? "screen \(event.name)" : "event \(event.name)"
        if !parameters.isEmpty {
            line += "  " + parameters.joined(separator: ", ")
        }
        add(line)
    }

    nonisolated func set(_ property: any Property) {
        add("property \(property.name)=\(property.value.asString)")
    }

    nonisolated func identify(_ identity: Identity) { add("identify \(identity.userId)") }

    nonisolated func reset() { add("reset") }

    nonisolated func start() { add("start") }

    nonisolated func flush() { add("flush") }

    nonisolated func setEnabled(_ enabled: Bool) { add("consent \(enabled)") }

    private nonisolated func add(_ line: String) {
        // In order: the main queue runs these one after another, as they were sent.
        DispatchQueue.main.async {
            self.lines.insert(line, at: 0)
        }
    }
}
