import HeraldCore

public struct ScreenViewLogEventTracker: LogEventTracker {
    private let event: any ScreenViewEvent
    private let logger: AnalyticsLogger

    public init(event: any ScreenViewEvent, logger: @escaping AnalyticsLogger) {
        self.event = event
        self.logger = logger
    }

    public func track() {
        logger(logRecord(kind: "screen", headline: event.name, parameters: event.parameters))
    }
}
