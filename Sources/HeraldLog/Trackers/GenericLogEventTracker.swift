import HeraldCore

public struct GenericLogEventTracker: LogEventTracker {
    private let event: any Event
    private let logger: AnalyticsLogger

    public init(event: any Event, logger: @escaping AnalyticsLogger) {
        self.event = event
        self.logger = logger
    }

    public func track() {
        logger(logRecord(kind: "event", headline: event.name, parameters: event.parameters))
    }
}
