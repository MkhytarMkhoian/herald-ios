/// A parameter or property value that keeps its type, so a number reaches the vendor as a number.
///
/// Vendors can sum or average numbers, but only group text. Vendors that take only text use
/// ``asString``.
///
/// ```swift
/// var parameters: [String: AnalyticsValue] {
///     ["plan": .string(plan), "seats": .int(seats), "price": .double(9.99), "trial": .bool(false)]
/// }
/// ```
public enum AnalyticsValue: Sendable, Hashable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    /// The value as text, for vendors that take only text. A double keeps its point: `3.0`.
    public var asString: String {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return String(value)
        case .double(let value):
            return String(value)
        case .bool(let value):
            return String(value)
        }
    }
}
