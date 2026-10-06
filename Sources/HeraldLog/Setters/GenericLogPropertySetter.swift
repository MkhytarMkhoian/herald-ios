import HeraldCore

public struct GenericLogPropertySetter: LogPropertySetter {
    private let property: any Property
    private let logger: AnalyticsLogger

    public init(property: any Property, logger: @escaping AnalyticsLogger) {
        self.property = property
        self.logger = logger
    }

    public func set() {
        logger(logRecord(kind: "prop", headline: "\(property.name) = \(property.value.asString)"))
    }
}
