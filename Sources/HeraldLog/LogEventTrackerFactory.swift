import HeraldCore

/// Decides what the log gets for an event: `claimed` with the calls to make, `dropped` to send
/// nothing, or `declined` to let the next factory decide.
public protocol LogEventTrackerFactory: Sendable {
    func create(_ event: any Event) throws -> Resolution<any LogEventTracker>
}

/// Asks each factory in order and uses the first answer that isn't `declined`. If all decline,
/// nothing is sent. Stops the app if a ``FallbackFactory`` isn't last.
public struct CompositeLogEventTrackerFactory: LogEventTrackerFactory {
    private let factories: [any LogEventTrackerFactory]

    public init(_ factories: [any LogEventTrackerFactory]) {
        requireFallbackLast(factories)
        self.factories = factories
    }

    public func create(_ event: any Event) throws -> Resolution<any LogEventTracker> {
        try Resolution.firstOf(factories) { factory in try factory.create(event) }
    }
}
