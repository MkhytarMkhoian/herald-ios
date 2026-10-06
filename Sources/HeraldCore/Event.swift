/// Something that happened in the app.
///
/// ``name`` identifies it and ``parameters`` carries its data.
///
/// ```swift
/// struct CheckoutStarted: Event {
///     let plan: String
///     let seats: Int
///
///     var name: String { "checkout_started" }
///     var parameters: [String: AnalyticsValue] { ["plan": .string(plan), "seats": .int(seats)] }
/// }
/// ```
public protocol Event: Sendable {
    var name: String { get }
    var parameters: [String: AnalyticsValue] { get }
}

extension Event {
    /// No parameters, unless the event has its own.
    public var parameters: [String: AnalyticsValue] { [:] }
}

/// A screen becoming visible. Its ``Event/name`` is the screen's name.
///
/// Vendors with a screen-view event of their own send it that way. To show a different name in one
/// vendor's screen reports, put a factory for that event before the vendor's screen-view factory.
public protocol ScreenViewEvent: Event {}
