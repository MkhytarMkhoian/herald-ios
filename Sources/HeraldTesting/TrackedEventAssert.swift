import HeraldCore
import Testing

/// Checks on one tracked event, given to the closure of
/// ``FakeAnalyticsProvider/assertTracked(_:sourceLocation:_:)``.
///
/// Each check compares by type too, so `param("seats", 3)` fails against the text `"3"`.
public struct TrackedEventAssert {
    private let name: String
    private let fail: (String, SourceLocation) -> Void

    /// The event, for checks the methods here don't cover.
    public let event: any Event

    init(name: String, event: any Event, fail: @escaping (String, SourceLocation) -> Void) {
        self.name = name
        self.event = event
        self.fail = fail
    }

    /// Asserts that the event has the parameter `key` with `value`.
    public func param(
        _ key: String, _ value: AnalyticsValue, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        guard let actual = event.parameters[key] else {
            fail(
                "Event '\(name)' has no parameter '\(key)'\(describe(event.parameters)).",
                sourceLocation)
            return
        }
        if actual != value {
            fail(
                "Event '\(name)' parameter '\(key)' was \(actual), expected \(value).",
                sourceLocation)
        }
    }

    public func param(
        _ key: String, _ value: String, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        param(key, .string(value), sourceLocation: sourceLocation)
    }

    public func param(
        _ key: String, _ value: Int, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        param(key, .int(value), sourceLocation: sourceLocation)
    }

    public func param(
        _ key: String, _ value: Double, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        param(key, .double(value), sourceLocation: sourceLocation)
    }

    public func param(
        _ key: String, _ value: Bool, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        param(key, .bool(value), sourceLocation: sourceLocation)
    }

    public func noParameters(sourceLocation: SourceLocation = #_sourceLocation) {
        if !event.parameters.isEmpty {
            fail(
                "Expected '\(name)' to carry no parameters, but it carried"
                    + "\(describe(event.parameters)).",
                sourceLocation)
        }
    }
}
