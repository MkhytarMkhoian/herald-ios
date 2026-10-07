import HeraldCore

protocol EventsAPI: Sendable {
    func send(name: String, parameters: [String: String]) async throws
}

// --8<-- [start:backend]
struct BackendAnalytics: EventTrackerService {
    let api: any EventsAPI

    func track(_ event: any Event) {
        var parameters: [String: String] = [:]
        for (key, value) in event.parameters {
            parameters[key] = value.asString
        }
        // A network request is slow, so it runs in a Task and `track` returns at once. A failure
        // reported from that Task still reaches Herald's error reporter.
        Task {
            do {
                try await api.send(name: event.name, parameters: parameters)
            } catch {
                Herald.reportFailure(error)
            }
        }
    }
}
// --8<-- [end:backend]

/// An event with personal data, which must stay on the device.
protocol PersonalDataEvent: Event {}

// --8<-- [start:decorators]
/// Sends only some events, for a vendor that charges per event.
struct SampledEventTracker: EventTrackerService {
    let inner: any EventTrackerService
    let rate: Double

    func track(_ event: any Event) {
        if Double.random(in: 0..<1) < rate {
            inner.track(event)
        }
    }
}

struct ExceptEventTracker: EventTrackerService {
    let inner: any EventTrackerService
    let excluded: @Sendable (any Event) -> Bool

    func track(_ event: any Event) {
        if !excluded(event) {
            inner.track(event)
        }
    }
}

extension EventTrackerService {
    func sampled(_ rate: Double) -> any EventTrackerService {
        SampledEventTracker(inner: self, rate: rate)
    }

    func except(_ excluded: @escaping @Sendable (any Event) -> Bool) -> any EventTrackerService {
        ExceptEventTracker(inner: self, excluded: excluded)
    }
}
// --8<-- [end:decorators]

func register(api: any EventsAPI, adjustTracker: any EventTrackerService) -> Herald {
    // --8<-- [start:register]
    let herald = Herald(providers: [
        HeraldProvider(
            name: "backend",
            events: BackendAnalytics(api: api).except { event in event is any PersonalDataEvent }
        ),
        HeraldProvider(name: "adjust", events: adjustTracker.sampled(0.1)),
    ])
    // --8<-- [end:register]
    return herald
}
