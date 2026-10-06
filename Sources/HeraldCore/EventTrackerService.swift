/// Somewhere an ``Event`` can be sent.
///
/// Vendor adapters, ``Herald`` and your own decorators implement it. A class that only tracks
/// events should depend on this, not on ``Herald``.
///
/// ```swift
/// // Keeps events with personal data away from `inner`.
/// struct ExceptPersonalDataTracker: EventTrackerService {
///     let inner: any EventTrackerService
///
///     func track(_ event: any Event) {
///         if !(event is PersonalDataEvent) {
///             inner.track(event)
///         }
///     }
/// }
/// ```
public protocol EventTrackerService: Sendable {
    func track(_ event: any Event)
}
