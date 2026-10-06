import HeraldCore

public protocol LogPropertySetterFactory: Sendable {
    func create(_ property: any Property) throws -> Resolution<any LogPropertySetter>
}

/// Asks each factory in order and uses the first answer that isn't `declined`. If all decline,
/// nothing is sent. Stops the app if a ``FallbackFactory`` isn't last.
public struct CompositeLogPropertySetterFactory: LogPropertySetterFactory {
    private let factories: [any LogPropertySetterFactory]

    public init(_ factories: [any LogPropertySetterFactory]) {
        requireFallbackLast(factories)
        self.factories = factories
    }

    public func create(_ property: any Property) throws -> Resolution<any LogPropertySetter> {
        try Resolution.firstOf(factories) { factory in try factory.create(property) }
    }
}
