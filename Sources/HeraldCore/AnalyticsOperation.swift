/// Which call failed: tracking an event, setting a property, and so on.
///
/// Holds names only, never values, so no personal data reaches the error reporter.
public enum AnalyticsOperation: Sendable, Hashable, CustomStringConvertible {
    case track(eventName: String)
    case setProperty(propertyName: String)
    case identify
    case reset
    case start
    case flush
    case setEnabled(Bool)

    public var description: String {
        switch self {
        case .track(let eventName):
            return "Track(\(eventName))"
        case .setProperty(let propertyName):
            return "SetProperty(\(propertyName))"
        case .identify:
            return "Identify"
        case .reset:
            return "Reset"
        case .start:
            return "Start"
        case .flush:
            return "Flush"
        case .setEnabled(let enabled):
            return "SetEnabled(\(enabled))"
        }
    }
}
