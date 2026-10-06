/// A factory that answers for everything, so it must be last in a chain: the generic factories,
/// which send everything, and the `RequireMapped` ones, which throw.
public protocol FallbackFactory {}

/// Stops the app if `factories` has more than one ``FallbackFactory``, or one that isn't last.
///
/// Composite factories call it when they're built, so a wrong chain fails at start-up, with a
/// message that names the factory to move.
public func requireFallbackLast(_ factories: [Any]) {
    if let problem = fallbackOrderProblem(factories) {
        preconditionFailure(problem)
    }
}

/// What's wrong with the order of `factories`, or `nil` if nothing is.
func fallbackOrderProblem(_ factories: [Any]) -> String? {
    var positions: [Int] = []
    for index in factories.indices where factories[index] is FallbackFactory {
        positions.append(index)
    }
    if positions.count > 1 {
        let names = positions.map { position in
            "\(type(of: factories[position])) (factory \(position + 1))"
        }
        return "A chain can end in one fallback factory; this one has \(positions.count): "
            + "\(names.joined(separator: ", "))."
    }
    if let position = positions.first, position != factories.count - 1 {
        return "\(type(of: factories[position])) answers for everything, so nothing placed after "
            + "it is ever asked. It is factory \(position + 1) of \(factories.count); "
            + "move it to the end."
    }
    return nil
}
