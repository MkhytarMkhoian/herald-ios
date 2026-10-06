import HeraldCore

/// One call the fake received.
///
/// All calls go into one list, in order, so a test can check the order across kinds, such as a
/// property set before the event that should carry it. A record prints as the line a failure shows.
///
/// Records are equal by kind and content: events by name and parameters, properties by name and
/// value.
public enum AnalyticsRecord: Sendable, Equatable, CustomStringConvertible {
    case tracked(any Event)
    case propertySet(any Property)
    case identified(Identity)
    case enabledSet(Bool)
    case reset
    case started
    case flushed

    /// The event, for a `tracked` record. `nil` for any other kind.
    public var event: (any Event)? {
        switch self {
        case .tracked(let event):
            return event
        default:
            return nil
        }
    }

    /// The property, for a `propertySet` record. `nil` for any other kind.
    public var property: (any Property)? {
        switch self {
        case .propertySet(let property):
            return property
        default:
            return nil
        }
    }

    /// The identity, for an `identified` record. `nil` for any other kind.
    public var identity: Identity? {
        switch self {
        case .identified(let identity):
            return identity
        default:
            return nil
        }
    }

    public static func == (left: AnalyticsRecord, right: AnalyticsRecord) -> Bool {
        switch (left, right) {
        case (.tracked(let leftEvent), .tracked(let rightEvent)):
            return leftEvent.name == rightEvent.name
                && leftEvent.parameters == rightEvent.parameters
        case (.propertySet(let leftProperty), .propertySet(let rightProperty)):
            return leftProperty.name == rightProperty.name
                && leftProperty.value == rightProperty.value
        case (.identified(let leftIdentity), .identified(let rightIdentity)):
            return leftIdentity == rightIdentity
        case (.enabledSet(let leftEnabled), .enabledSet(let rightEnabled)):
            return leftEnabled == rightEnabled
        case (.reset, .reset), (.started, .started), (.flushed, .flushed):
            return true
        default:
            return false
        }
    }

    public var description: String {
        switch self {
        case .tracked(let event):
            return "event    \(event.name)\(describe(event.parameters))"
        case .propertySet(let property):
            return "property \(property.name) = \(property.value.asString)"
        case .identified(let identity):
            return "identify \(identity.userId)"
        case .enabledSet(let enabled):
            return "enabled  \(enabled)"
        case .reset:
            return "reset"
        case .started:
            return "start"
        case .flushed:
            return "flush"
        }
    }
}

/// Parameters as failures show them: sorted by key, or nothing when there are none.
func describe(_ parameters: [String: AnalyticsValue]) -> String {
    if parameters.isEmpty {
        return ""
    }
    var entries: [String] = []
    for key in parameters.keys.sorted() {
        entries.append("\(key) = \(parameters[key]!.asString)")
    }
    return " { \(entries.joined(separator: ", ")) }"
}
