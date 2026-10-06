/// A lasting attribute, such as the user's plan, that vendors attach to later events.
///
/// The value keeps its type. Vendors that take only text use ``AnalyticsValue/asString``.
public protocol Property: Sendable {
    var name: String { get }
    var value: AnalyticsValue { get }
}

/// A property about the person, not the session. Vendors with a user profile store it there.
public protocol UserProperty: Property {}
