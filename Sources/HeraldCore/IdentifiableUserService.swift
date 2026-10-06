public protocol IdentifiableUserService: Sendable {
    func identify(_ identity: Identity)

    /// Forgets the current user. Call it on sign-out.
    func reset()
}
