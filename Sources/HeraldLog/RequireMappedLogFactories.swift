import HeraldCore

/// Fails for any event that reaches it, so the error reporter shows events nobody mapped. Put it
/// last in a chain.
public struct RequireMappedLogEventTrackerFactory: LogEventTrackerFactory, FallbackFactory {
    public init() {}

    public func create(_ event: any Event) throws -> Resolution<any LogEventTracker> {
        throw UnhandledEventError(event: event)
    }
}

public struct RequireMappedLogPropertySetterFactory: LogPropertySetterFactory, FallbackFactory {
    public init() {}

    public func create(_ property: any Property) throws -> Resolution<any LogPropertySetter> {
        throw UnhandledPropertyError(property: property)
    }
}
