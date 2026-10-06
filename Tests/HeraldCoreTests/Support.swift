import Foundation
import HeraldCore

struct TestEvent: Event {
    let name: String
    var parameters: [String: AnalyticsValue] = [:]
}

struct TestProperty: Property {
    let name: String
    let value: AnalyticsValue
}

struct TestError: Error, Equatable {
    let message: String
}

/// A list that Herald's queue appends to while a test reads it. The lock makes that safe, which
/// the compiler can't check: hence `@unchecked Sendable`.
final class SharedList<Element>: @unchecked Sendable {
    private let lock = NSLock()
    private var elements: [Element] = []

    var all: [Element] {
        lock.lock()
        defer { lock.unlock() }
        return elements
    }

    func append(_ element: Element) {
        lock.lock()
        defer { lock.unlock() }
        elements.append(element)
    }
}

/// Records each call it gets, also into `log` when given one, and reports `failure` for each call.
final class RecordingService: EventTrackerService, PropertyTrackerService,
    IdentifiableUserService, AnalyticsLifecycleService, ConsentService
{
    private let calls = SharedList<String>()
    private let log: SharedList<String>?
    private let failure: (any Error)?

    init(log: SharedList<String>? = nil, failure: (any Error)? = nil) {
        self.log = log
        self.failure = failure
    }

    var received: [String] { calls.all }

    func track(_ event: any Event) { record("track \(event.name)") }

    func set(_ property: any Property) { record("set \(property.name)") }

    func identify(_ identity: Identity) { record("identify \(identity.userId)") }

    func reset() { record("reset") }

    func start() { record("start") }

    func flush() { record("flush") }

    func setEnabled(_ enabled: Bool) { record("enabled \(enabled)") }

    private func record(_ call: String) {
        calls.append(call)
        log?.append(call)
        if let failure {
            Herald.reportFailure(failure)
        }
    }
}

/// Tracks events by calling `onTrack`.
struct TestEventTracker: EventTrackerService {
    let onTrack: @Sendable (any Event) -> Void

    func track(_ event: any Event) {
        onTrack(event)
    }
}
