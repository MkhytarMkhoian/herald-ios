import HeraldCore

/// Sends events and properties to the log, as its factory chains decide. The calls for one event
/// run in order, and if one fails the rest don't run. Anything no factory claims isn't sent.
///
/// ```swift
/// let logger: AnalyticsLogger = { message in print(message) }
/// let logTracker = LogAnalyticsTrackerService(
///     eventTrackerFactory: CompositeLogEventTrackerFactory([
///         ScreenViewLogEventTrackerFactory(logger: logger),
///         GenericLogEventTrackerFactory(logger: logger),
///     ]),
///     propertySetterFactory: GenericLogPropertySetterFactory(logger: logger)
/// )
/// ```
public struct LogAnalyticsTrackerService: EventTrackerService, PropertyTrackerService {
    private let eventTrackerFactory: any LogEventTrackerFactory
    private let propertySetterFactory: any LogPropertySetterFactory

    public init(
        eventTrackerFactory: any LogEventTrackerFactory,
        propertySetterFactory: any LogPropertySetterFactory
    ) {
        self.eventTrackerFactory = eventTrackerFactory
        self.propertySetterFactory = propertySetterFactory
    }

    public func track(_ event: any Event) {
        do {
            for tracker in try eventTrackerFactory.create(event).handlers() {
                try tracker.track()
            }
        } catch {
            Herald.reportFailure(error)
        }
    }

    public func set(_ property: any Property) {
        do {
            for setter in try propertySetterFactory.create(property).handlers() {
                try setter.set()
            }
        } catch {
            Herald.reportFailure(error)
        }
    }
}
