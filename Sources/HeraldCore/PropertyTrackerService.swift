/// Somewhere a ``Property`` can be set. Like ``EventTrackerService``, for properties.
public protocol PropertyTrackerService: Sendable {
    func set(_ property: any Property)
}
