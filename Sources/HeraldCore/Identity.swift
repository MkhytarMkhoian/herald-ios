/// The current user.
///
/// Printing it hides ``userId``, so an identity printed by accident doesn't leak it into logs or
/// crash reports. Use ``userId`` when you really need it.
public struct Identity: Sendable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    public let userId: String

    public init(userId: String) {
        self.userId = userId
    }

    public var description: String { "Identity(…)" }

    public var debugDescription: String { "Identity(…)" }
}
