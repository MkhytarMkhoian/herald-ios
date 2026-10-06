/// Where the log adapter prints.
///
/// Every record is one call with one string, already formatted. Point it at whatever logging you
/// use: `{ message in print(message) }`, or Apple's unified log, which shows in Xcode's console and
/// in the Console app:
///
/// ```swift
/// let log = Logger(subsystem: "com.example.app", category: "analytics")
/// let logger: AnalyticsLogger = { message in log.debug("\(message, privacy: .public)") }
/// ```
public typealias AnalyticsLogger = @Sendable (String) -> Void
