import HeraldCore

/// Prints the calls that are not events or properties, so the log shows the whole story: whether
/// consent was ever granted, whether `identify` ran before the first event, whether `reset` fired
/// on sign-out.
///
/// The user id is printed as-is. That is the point in a debug build and a leak in a release one,
/// so register this provider only in debug builds, like the rest of the log adapter:
///
/// ```swift
/// #if DEBUG
/// providers.append(
///     HeraldProvider(
///         name: "log",
///         events: logTracker,
///         properties: logTracker,
///         identity: logService,
///         lifecycle: logService,
///         consent: logService
///     )
/// )
/// #endif
/// ```
public struct LogAnalyticsService: IdentifiableUserService, AnalyticsLifecycleService,
    ConsentService
{
    private let logger: AnalyticsLogger

    public init(logger: @escaping AnalyticsLogger) {
        self.logger = logger
    }

    public func identify(_ identity: Identity) {
        logger(logRecord(kind: "user", headline: identity.userId))
    }

    public func reset() {
        logger(logRecord(kind: "reset", headline: ""))
    }

    public func start() {
        logger(logRecord(kind: "start", headline: ""))
    }

    public func flush() {
        logger(logRecord(kind: "flush", headline: ""))
    }

    public func setEnabled(_ enabled: Bool) {
        logger(logRecord(kind: "enabled", headline: "\(enabled)"))
    }
}
