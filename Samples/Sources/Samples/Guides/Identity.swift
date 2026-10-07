import HeraldCore

protocol Session {
    var userId: String? { get }
}

// --8<-- [start:session]
final class AnalyticsIdentity {
    private let identity: any IdentifiableUserService

    init(identity: any IdentifiableUserService) {
        self.identity = identity
    }

    func onSignedIn(userId: String) {
        identity.identify(Identity(userId: userId))
    }

    func onSignedOut() {
        identity.reset()
    }

    /// Call it at every app start: some vendors forget the user between launches.
    func restore(session: any Session) {
        if let userId = session.userId {
            identity.identify(Identity(userId: userId))
        }
    }
}
// --8<-- [end:session]
