/// Starts a vendor and sends what it has buffered.
public protocol AnalyticsLifecycleService: Sendable {
    /// Starts the vendor SDK. Call it once, when the app starts.
    func start()

    /// Asks the vendor to send what it has buffered. Useful when consent is revoked or the app goes
    /// to the background.
    func flush()
}
