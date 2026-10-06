/// A factory's answer for one event or property:
///
/// - `claimed`: mine, send it with these handlers.
/// - `dropped`: mine, send nothing. Later factories aren't asked.
/// - `declined`: not mine, ask the next factory.
///
/// ```swift
/// func create(_ event: any Event) throws -> Resolution<FirebaseEventTracker> {
///     if let checkout = event as? CheckoutStarted {
///         return .claimed([CheckoutTracker(event: checkout, analytics: analytics)])
///     }
///     if event is DebugPing {
///         return .dropped
///     }
///     return .declined
/// }
/// ```
public enum Resolution<Handler> {
    /// Give at least one handler. To claim something and send nothing, use `dropped`.
    case claimed([Handler])
    case dropped
    case declined

    /// The handlers to run: none for `dropped` and `declined`. Throws if `claimed` has none.
    public func handlers() throws -> [Handler] {
        switch self {
        case .claimed(let handlers):
            if handlers.isEmpty {
                throw ClaimedWithoutHandlersError()
            }
            return handlers
        case .dropped, .declined:
            return []
        }
    }

    /// Asks each factory in order and returns the first answer that isn't `declined`, or `declined`
    /// if all decline. The factories after the one that answers aren't asked. Composite factories
    /// use it to run their chain:
    ///
    /// ```swift
    /// try Resolution.firstOf(factories) { factory in try factory.create(event) }
    /// ```
    public static func firstOf<Factory>(
        _ factories: [Factory],
        asking create: (Factory) throws -> Resolution<Handler>
    ) throws -> Resolution<Handler> {
        for factory in factories {
            let resolution = try create(factory)
            switch resolution {
            case .declined:
                continue
            case .claimed, .dropped:
                return resolution
            }
        }
        return .declined
    }
}

extension Resolution: Equatable where Handler: Equatable {}

extension Resolution: Sendable where Handler: Sendable {}

struct ClaimedWithoutHandlersError: Error, CustomStringConvertible {
    var description: String {
        "A factory claimed something with no handlers. Use .dropped to claim it and send nothing."
    }
}
