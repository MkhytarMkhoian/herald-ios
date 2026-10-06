import HeraldCore

/// Prints any event under its own name, with its parameters. Claims every event, so it goes last
/// in a chain.
public struct GenericLogEventTrackerFactory: LogEventTrackerFactory, FallbackFactory {
    private let logger: AnalyticsLogger

    public init(logger: @escaping AnalyticsLogger) {
        self.logger = logger
    }

    public func create(_ event: any Event) -> Resolution<any LogEventTracker> {
        .claimed([GenericLogEventTracker(event: event, logger: logger)])
    }
}

/// Claims every ``ScreenViewEvent`` and prints it as a screen record. Declines everything else.
public struct ScreenViewLogEventTrackerFactory: LogEventTrackerFactory {
    private let logger: AnalyticsLogger

    public init(logger: @escaping AnalyticsLogger) {
        self.logger = logger
    }

    public func create(_ event: any Event) -> Resolution<any LogEventTracker> {
        if let screenView = event as? any ScreenViewEvent {
            return .claimed([ScreenViewLogEventTracker(event: screenView, logger: logger)])
        }
        return .declined
    }
}

/// Prints any property as `name = value`. Claims every property, so it goes last in a chain.
public struct GenericLogPropertySetterFactory: LogPropertySetterFactory, FallbackFactory {
    private let logger: AnalyticsLogger

    public init(logger: @escaping AnalyticsLogger) {
        self.logger = logger
    }

    public func create(_ property: any Property) -> Resolution<any LogPropertySetter> {
        .claimed([GenericLogPropertySetter(property: property, logger: logger)])
    }
}
