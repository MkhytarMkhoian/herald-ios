/// A vendor call that failed: which vendor, which call, and the error.
///
/// It holds no event parameters, property values or user id, so it's safe to send to a crash tool.
/// It prints as one line, like `analytics failed on Track(checkout_started): <error>`.
public struct AnalyticsFailure: Sendable, CustomStringConvertible {
    public let provider: String
    public let operation: AnalyticsOperation
    public let error: any Error

    public init(provider: String, operation: AnalyticsOperation, error: any Error) {
        self.provider = provider
        self.operation = operation
        self.error = error
    }

    public var description: String { "\(provider) failed on \(operation): \(error)" }
}

/// Where ``Herald`` reports a vendor that failed.
///
/// Without a reporter you won't see failures, so send them to your crash or logging tool. Herald
/// calls it on its own background queue:
///
/// ```swift
/// errorReporter: { failure in
///     Crashlytics.crashlytics().record(error: failure.error, userInfo: ["call": "\(failure)"])
/// }
/// ```
public typealias AnalyticsErrorReporter = @Sendable (AnalyticsFailure) -> Void
