/// One vendor: a name and the capabilities it has.
///
/// An adapter with several capabilities is passed under each. ``name`` shows up in failure reports,
/// so pick one you'll recognise.
///
/// To skip or sample events for one vendor, wrap its capability in a decorator, like the one shown
/// on ``EventTrackerService``:
///
/// ```swift
/// HeraldProvider(name: "attribution", events: ExceptPersonalDataTracker(inner: attributionTracker))
/// ```
public struct HeraldProvider: Sendable {
    public let name: String
    public let events: (any EventTrackerService)?
    public let properties: (any PropertyTrackerService)?
    public let identity: (any IdentifiableUserService)?
    public let lifecycle: (any AnalyticsLifecycleService)?
    public let consent: (any ConsentService)?

    /// Stops the app if `name` is blank or no capability is given.
    public init(
        name: String,
        events: (any EventTrackerService)? = nil,
        properties: (any PropertyTrackerService)? = nil,
        identity: (any IdentifiableUserService)? = nil,
        lifecycle: (any AnalyticsLifecycleService)? = nil,
        consent: (any ConsentService)? = nil
    ) {
        if name.allSatisfy({ character in character.isWhitespace }) {
            preconditionFailure(
                "A provider needs a name; it is what identifies it in a failure report.")
        }
        let hasCapability =
            events != nil || properties != nil || identity != nil || lifecycle != nil
            || consent != nil
        if !hasCapability {
            preconditionFailure(
                "Provider '\(name)' was registered with no capabilities, so it can never be called."
            )
        }
        self.name = name
        self.events = events
        self.properties = properties
        self.identity = identity
        self.lifecycle = lifecycle
        self.consent = consent
    }
}
