import Foundation
import HeraldCore
import Testing

/// A vendor that records calls instead of sending them, for tests.
///
/// It has all five capabilities. Register it with a real `Herald`, so the test also runs your
/// setup, or pass it straight to the class under test:
///
/// ```swift
/// let analytics = FakeAnalyticsProvider()
/// let viewModel = CheckoutViewModel(analytics: analytics)
///
/// viewModel.payTapped()
///
/// analytics.assertTracked("checkout_pay_tapped") { event in
///     event.param("plan", "pro")
/// }
/// analytics.assertNothingElseTracked()
/// ```
///
/// A failed assertion fails the test, in Swift Testing and in XCTest alike, at the line that made
/// it, and lists everything recorded.
///
/// Calls can come from any thread. A lock keeps the records safe, which the compiler can't check:
/// hence `@unchecked Sendable`.
public final class FakeAnalyticsProvider: EventTrackerService, PropertyTrackerService,
    IdentifiableUserService, AnalyticsLifecycleService, ConsentService, @unchecked Sendable
{
    private let lock = NSLock()
    private var recorded: [AnalyticsRecord] = []
    private var accountedFor: Set<Int> = []

    public init() {}

    /// Everything received, oldest first. Later calls don't change a list already read.
    public var records: [AnalyticsRecord] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    public var events: [any Event] {
        var events: [any Event] = []
        for record in records {
            if let event = record.event {
                events.append(event)
            }
        }
        return events
    }

    public var properties: [any Property] {
        var properties: [any Property] = []
        for record in records {
            if let property = record.property {
                properties.append(property)
            }
        }
        return properties
    }

    public func track(_ event: any Event) { record(.tracked(event)) }

    public func set(_ property: any Property) { record(.propertySet(property)) }

    public func identify(_ identity: Identity) { record(.identified(identity)) }

    public func reset() { record(.reset) }

    public func start() { record(.started) }

    public func flush() { record(.flushed) }

    public func setEnabled(_ enabled: Bool) { record(.enabledSet(enabled)) }

    /// Forgets everything, including which events were already asserted on.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        recorded = []
        accountedFor = []
    }

    /// Asserts that exactly one event called `name` was tracked, then runs `check` on it.
    ///
    /// Exactly one, so a duplicated event fails instead of passing. Use ``assertTrackedTimes(_:_:sourceLocation:)``
    /// when repeats are expected.
    ///
    /// ```swift
    /// analytics.assertTracked("checkout_started") { event in
    ///     event.param("plan", "pro")
    ///     event.param("seats", 3)
    /// }
    /// ```
    public func assertTracked(
        _ name: String,
        sourceLocation: SourceLocation = #_sourceLocation,
        _ check: ((TrackedEventAssert) -> Void)? = nil
    ) {
        let matches = trackedPositions(of: name)
        if matches.isEmpty {
            fail("Expected an event named '\(name)', but it was never tracked.", sourceLocation)
            return
        }
        if matches.count > 1 {
            fail(
                "Expected one event named '\(name)', but \(matches.count) were tracked. "
                    + "Use assertTrackedTimes(\"\(name)\", \(matches.count)) if that is intended.",
                sourceLocation)
            return
        }
        markAccountedFor(matches)
        if let check, let event = records[matches[0]].event {
            check(TrackedEventAssert(name: name, event: event, fail: fail))
        }
    }

    public func assertTrackedTimes(
        _ name: String, _ times: Int, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let matches = trackedPositions(of: name)
        if matches.count != times {
            fail(
                "Expected '\(name)' to be tracked \(times) times, but it was tracked "
                    + "\(matches.count) times.",
                sourceLocation)
        }
        markAccountedFor(matches)
    }

    public func assertNotTracked(_ name: String, sourceLocation: SourceLocation = #_sourceLocation)
    {
        if !trackedPositions(of: name).isEmpty {
            fail("Expected '\(name)' never to be tracked.", sourceLocation)
        }
    }

    public func assertNothingTracked(sourceLocation: SourceLocation = #_sourceLocation) {
        let tracked = events
        if !tracked.isEmpty {
            fail("Expected no events, but \(tracked.count) were tracked.", sourceLocation)
        }
    }

    /// Asserts that every tracked event was already checked by an earlier assertion, so an
    /// unexpected event, such as a duplicate, doesn't go unnoticed.
    public func assertNothingElseTracked(sourceLocation: SourceLocation = #_sourceLocation) {
        lock.lock()
        var unexpected: [String] = []
        for position in recorded.indices where !accountedFor.contains(position) {
            if let event = recorded[position].event {
                unexpected.append(event.name)
            }
        }
        lock.unlock()
        if !unexpected.isEmpty {
            fail(
                "Unexpected events tracked: \(unexpected.joined(separator: ", ")).", sourceLocation)
        }
    }

    /// Asserts that the property `name` currently has `value`, meaning the last value it was set
    /// to. If it had the right value and was then overwritten, this fails and shows every value.
    ///
    /// It compares by type too, so `assertPropertySet("seats", 3)` fails against the text `"3"`.
    public func assertPropertySet(
        _ name: String, _ value: AnalyticsValue, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        var history: [AnalyticsValue] = []
        for property in properties where property.name == name {
            history.append(property.value)
        }
        guard let last = history.last else {
            fail("Expected property '\(name)' to be set, but it never was.", sourceLocation)
            return
        }
        if last != value {
            let values = history.map { value in "\(value)" }.joined(separator: " then ")
            fail(
                "Expected property '\(name)' to be \(value), but it was set to \(values).",
                sourceLocation)
        }
    }

    public func assertPropertySet(
        _ name: String, _ value: String, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        assertPropertySet(name, .string(value), sourceLocation: sourceLocation)
    }

    public func assertPropertySet(
        _ name: String, _ value: Int, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        assertPropertySet(name, .int(value), sourceLocation: sourceLocation)
    }

    public func assertPropertySet(
        _ name: String, _ value: Double, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        assertPropertySet(name, .double(value), sourceLocation: sourceLocation)
    }

    public func assertPropertySet(
        _ name: String, _ value: Bool, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        assertPropertySet(name, .bool(value), sourceLocation: sourceLocation)
    }

    /// Asserts that the user was identified as `userId` at some point, even if `reset` came later.
    /// Use ``records`` to check the order.
    public func assertIdentified(
        _ userId: String, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for record in records {
            if record.identity?.userId == userId {
                return
            }
        }
        fail("Expected the user to be identified as '\(userId)'.", sourceLocation)
    }

    private func record(_ record: AnalyticsRecord) {
        lock.lock()
        defer { lock.unlock() }
        recorded.append(record)
    }

    private func markAccountedFor(_ positions: [Int]) {
        lock.lock()
        defer { lock.unlock() }
        accountedFor.formUnion(positions)
    }

    private func trackedPositions(of name: String) -> [Int] {
        let records = records
        var positions: [Int] = []
        for position in records.indices {
            if records[position].event?.name == name {
                positions.append(position)
            }
        }
        return positions
    }

    /// Fails the test with `message`, followed by everything recorded.
    private func fail(_ message: String, _ sourceLocation: SourceLocation) {
        let records = records
        var timeline = "  (nothing was recorded)"
        if !records.isEmpty {
            var lines: [String] = []
            for position in records.indices {
                lines.append("  \(position + 1). \(records[position])")
            }
            timeline = lines.joined(separator: "\n")
        }
        Issue.record("\(message)\n\nRecorded:\n\(timeline)", sourceLocation: sourceLocation)
    }
}
