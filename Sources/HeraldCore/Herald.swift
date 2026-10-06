/// Sends each call to every vendor.
///
/// It implements all five capabilities. Give your classes the protocol they need, such as
/// ``EventTrackerService``, not `Herald` itself.
///
/// ```swift
/// let herald = Herald(
///     providers: [
///         HeraldProvider(
///             name: "analytics",
///             events: analyticsTracker,
///             properties: analyticsTracker,
///             identity: analyticsService,
///             lifecycle: analyticsService,
///             consent: analyticsService
///         ),
///         HeraldProvider(name: "attribution", events: attributionTracker),
///     ],
///     errorReporter: { failure in crashReporter.record(failure.error) }
/// )
/// ```
///
/// ## Order
///
/// A call reaches every vendor, in the order they were registered, before it returns. So after
///
/// ```swift
/// herald.setEnabled(false)
/// herald.track(event)
/// ```
///
/// every vendor is turned off before it gets the event.
///
/// Herald calls the vendors on the thread you call it from, and vendor SDKs do their own work in the
/// background, so a call takes very little time. A provider of your own must return quickly too:
/// do slow work, such as a network request, on a queue of its own.
///
/// ## Failures
///
/// A vendor that can't send a call reports it with ``reportFailure(_:)``, and the other vendors
/// still get the call. Herald sends the failure to the error reporter right away, with the vendor's
/// name and the call. Calls on `Herald` itself never fail.
///
/// Every provider needs its own name. A repeated name stops the app.
public final class Herald: EventTrackerService, PropertyTrackerService, IdentifiableUserService,
    AnalyticsLifecycleService, ConsentService
{
    private let providers: [HeraldProvider]
    private let errorReporter: AnalyticsErrorReporter?

    /// Failures go to `errorReporter`. Without one, they are dropped.
    public init(providers: [HeraldProvider], errorReporter: AnalyticsErrorReporter? = nil) {
        var names: Set<String> = []
        for provider in providers {
            if names.contains(provider.name) {
                preconditionFailure(
                    "Two providers are named '\(provider.name)', so a failure report couldn't tell "
                        + "them apart. Give each provider its own name."
                )
            }
            names.insert(provider.name)
        }
        self.providers = providers
        self.errorReporter = errorReporter
    }

    public func track(_ event: any Event) {
        send(.track(eventName: event.name)) { provider in
            provider.events?.track(event)
        }
    }

    public func set(_ property: any Property) {
        send(.setProperty(propertyName: property.name)) { provider in
            provider.properties?.set(property)
        }
    }

    public func identify(_ identity: Identity) {
        send(.identify) { provider in
            provider.identity?.identify(identity)
        }
    }

    public func reset() {
        send(.reset) { provider in
            provider.identity?.reset()
        }
    }

    public func start() {
        send(.start) { provider in
            provider.lifecycle?.start()
        }
    }

    public func flush() {
        send(.flush) { provider in
            provider.lifecycle?.flush()
        }
    }

    public func setEnabled(_ enabled: Bool) {
        send(.setEnabled(enabled)) { provider in
            provider.consent?.setEnabled(enabled)
        }
    }

    /// Reports that a vendor couldn't send the current call, such as an event it refuses.
    ///
    /// Vendor adapters call it from their capability methods, while Herald is calling them. Herald
    /// adds the vendor's name and the call, and sends the failure to its error reporter.
    ///
    /// ```swift
    /// func track(_ event: any Event) {
    ///     do {
    ///         try send(event)
    ///     } catch {
    ///         Herald.reportFailure(error)
    ///     }
    /// }
    /// ```
    ///
    /// Call it while Herald is calling the vendor: from the method itself, or from a `Task` it
    /// starts. Herald can't tell which vendor and call a report from anywhere else belongs to, such
    /// as a completion handler on another queue. That report stops a debug build with a message,
    /// and is dropped in a release build.
    public static func reportFailure(_ error: any Error) {
        guard let call = providerCall else {
            assertionFailure(
                "Herald.reportFailure was called outside a Herald call, so nobody can report it: "
                    + "\(error)")
            return
        }
        let failure = AnalyticsFailure(
            provider: call.provider, operation: call.operation, error: error)
        call.errorReporter?(failure)
    }

    /// Calls every provider in order. `call` does nothing for a provider without the capability.
    private func send(_ operation: AnalyticsOperation, _ call: (HeraldProvider) -> Void) {
        for provider in providers {
            let providerCall = ProviderCall(
                provider: provider.name, operation: operation, errorReporter: errorReporter)
            Herald.$providerCall.withValue(providerCall) {
                call(provider)
            }
        }
    }

    /// The vendor call Herald is making right now, so `reportFailure` can say which vendor and call
    /// failed. A task-local value: `withValue` sets it only while its block runs, and only for the
    /// code running that block, so calls made at the same time from other threads each see their
    /// own. A `Task` started inside the block keeps a copy.
    @TaskLocal private static var providerCall: ProviderCall?
}

private struct ProviderCall: Sendable {
    let provider: String
    let operation: AnalyticsOperation
    let errorReporter: AnalyticsErrorReporter?
}
