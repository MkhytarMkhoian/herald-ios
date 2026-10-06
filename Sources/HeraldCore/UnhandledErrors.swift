/// Thrown by a `RequireMapped` factory when no factory claimed an event.
public struct UnhandledEventError: Error, CustomStringConvertible {
    public let event: any Event

    public init(event: any Event) {
        self.event = event
    }

    public var description: String {
        "No factory claimed event '\(event.name)' (\(type(of: event))). "
            + "Add a factory for it, or end the chain with a generic factory to send it as-is."
    }
}

/// Like ``UnhandledEventError``, for properties.
public struct UnhandledPropertyError: Error, CustomStringConvertible {
    public let property: any Property

    public init(property: any Property) {
        self.property = property
    }

    public var description: String {
        "No factory claimed property '\(property.name)' (\(type(of: property))). "
            + "Add a factory for it, or end the chain with a generic factory to set it as-is."
    }
}
